# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'base64'

module AppPerfRpm
  module Reporters
    class JsonClient
      def initialize(opts = { :url => nil, :collector => nil, :flush_interval => nil })
        @collector = opts[:collector]
        @flush_interval = opts[:flush_interval]
        @spans_uri = URI.parse(opts[:url])
      end

      def start
        @thread = Thread.new do
          loop do
            emit_batch(@collector.retrieve)
            sleep @flush_interval
          end
        end
      end

      def stop
        @thread.terminate if @thread
        emit_batch(@collector.retrieve)
      end

      private

      def compress_body(data)
        body = MessagePack.pack({
          "name" => AppPerfRpm.config.application_name,
          "host" => AppPerfRpm.host,
          "data" => data
        })

        compressed_body = Zlib::Deflate.deflate(body, Zlib::DEFAULT_COMPRESSION)
        Base64.encode64(compressed_body)
      end

      def emit_batch(spans)
        return if spans.empty?

        sock = Net::HTTP.new(@spans_uri.host, @spans_uri.port)
        sock.use_ssl = ::AppPerfRpm.config.ssl

        request = Net::HTTP::Post.new(@spans_uri.request_uri, {
          "Accept-Encoding" => "gzip",
          "User-Agent" => "gzip"
        })
        request.body = compress_body(spans)
        request.content_type = "application/octet-stream"

        response = sock.start do |http|
          http.read_timeout = 30
          http.request(request)
        end

        if response.code != 202
          STDERR.puts(response.body)
        end
      rescue => e
        STDERR.puts("Error emitting spans batch: #{e.message}\n#{e.backtrace.join("\n")}")
      end
    end
  end
end

# frozen_string_literal: true

require 'socket'

module AppPerfRpm
  module Tracing
    class Endpoint
      LOCAL_IP = (
        Socket.ip_address_list.detect(&:ipv4_private?) ||
        Socket.ip_address_list.reverse.detect(&:ipv4?)
      ).ip_address

      def self.local_endpoint(service_name)
        {
          "serviceName" => service_name,
          "ipv4" => LOCAL_IP
        }
      end
    end
  end
end

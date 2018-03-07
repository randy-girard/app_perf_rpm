# frozen_string_literal: true

module AppPerfRpm
  class Backtrace
    class << self
      def backtrace(opts = {})
        kind = opts[:kind]

        if kind
          bt = Kernel.caller
          bt = clean(bt)
          bt = filter(bt, kind)
          trim_backtrace(bt)
        end
      end

      def clean(backtrace)
        Array(backtrace)
          .map {|b| clean_line(b) }
          .select {|b| b !~ %r{lib/app_perf_rpm} }
      end

      def filter(backtrace, kind)
        case kind
        when :all
          backtrace
        when :app
          backtrace.select {|b| b =~ /\[APP_PATH\]/ }
        when :gem
          backtrace.select {|b| b =~ /\[GEM_PATH\]/ }
        else
          []
        end
      end

      #def source_extract(_backtrace = Kernel.caller(2))
      #  if(trace = _backtrace.first)
      #    file, line_number = extract_file_and_line_number(trace)

      #    {
      #      code: source_fragment(file, line_number),
      #      line_number: line_number
      #    }
      #  else
      #    nil
      #  end
      #end

      def source_extract(opts = {})
        backtrace = opts[:backtrace] || Kernel.caller(0)

        Array(backtrace).select {|bt| bt[/^#{::AppPerfRpm.config.app_root.to_s}\//] }.map do |trace|
          file, line_number = extract_file_and_line_number(trace)
          source_to_hash(file, line_number)
        end
      end

      def source_to_hash(file, line_number)
        {
          "file" => clean_line(file),
          "code" => source_fragment(file, line_number),
          "line_number" => line_number
        }
      end

      def clean_line(line)
        line
          .sub(/#{::AppPerfRpm.config.app_root.to_s}\//, "[APP_PATH]/")
          .sub(gems_regexp, '\2 (\3) [GEM_PATH]/\4')
      end

      private

      def gems_regexp
        gems_paths = (Gem.path | [Gem.default_dir]).map { |p| Regexp.escape(p) }
        if gems_paths
          %r{(#{gems_paths.join('|')})/gems/([^/]+)-([\w.]+)/(.*)}
        else
          nil
        end
      end

      def source_fragment(path, line)
        return unless AppPerfRpm.config.app_root
        full_path = AppPerfRpm.config.app_root.join(path)
        if File.exist?(full_path)
          File.open(full_path, "r") do |file|
            start = [line - 3, 0].max
            lines = file.each_line.drop(start).take(6)
            Hash[*(start + 1..(lines.count + start)).zip(lines).flatten]
          end
        end
      end

      def extract_file_and_line_number(trace)
        file, line = trace.match(/^(.+?):(\d+).*$/, &:captures) || trace
        [file, line.to_i]
      end

      def trim_backtrace(_backtrace, opts = {})
        kind = opts[:kind]

        return _backtrace unless _backtrace.is_a?(Array)

        length = _backtrace.size
        if length > 80
          trimmed = _backtrace[0, 80]
          trimmed += ['...[snip]...']
          trimmed += _backtrace[length - 20, 20]
        else
          trimmed = _backtrace
        end
        trimmed
      end
     end
  end
end

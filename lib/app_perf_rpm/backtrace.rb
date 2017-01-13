module AppPerfRpm
  class Backtrace
    class Cleaner
      def initialize
        @filters, @silencers = [], []
      end

      def clean(backtrace, kind = :silent)
        filtered = filter_backtrace(backtrace)

        case kind
        when :silent
          silence(filtered)
        when :noise
          noise(filtered)
        else
          filtered
        end
      end
      alias :filter :clean

      def add_filter(&block)
        @filters << block
      end

      def add_silencer(&block)
        @silencers << block
      end

      def add_gem_filters
        gems_paths = (Gem.path | [Gem.default_dir]).map { |p| Regexp.escape(p) }
        return if gems_paths.empty?

        gems_regexp = %r{(#{gems_paths.join('|')})/gems/([^/]+)-([\w.]+)/(.*)}
        add_filter { |line| line.sub(gems_regexp, '\2 (\3) \4') }
      end

      def remove_silencers!
        @silencers = []
      end

      def remove_filters!
        @filters = []
      end

      private
      def filter_backtrace(backtrace)
        limit = @filters.size
        i = 0
        while i < limit
          f = @filters[i]
          i += 1
          backtrace = backtrace.map { |line| f.call(line) }
        end

        backtrace
      end

      def silence(backtrace)
        limit = @silencers.size
        i = 0
        while i < limit
          s = @silencers[i]
          i += 1
          backtrace = backtrace.reject { |line| s.call(line) }
        end

        backtrace
      end

      def noise(backtrace)
        backtrace - silence(backtrace)
      end
    end

    class << self
      APP_DIRS_PATTERN = /^\/?(app|config|lib|test)/
      RENDER_TEMPLATE_PATTERN = /:in `_render_template_\w*'/

      def application_trace
        clean_backtrace(:silent)
      end

      def framework_trace
        clean_backtrace(:noise)
      end

      def full_trace
        clean_backtrace(:all)
      end

      def base_backtrace
        Kernel.caller
      end

      def backtrace
        base_backtrace
      end

      def clean_backtrace(*args)
        backtrace_cleaner.clean(base_backtrace, *args)
      end

      def backtrace_cleaner
        if @backtrace_cleaner.nil?
          @backtrace_cleaner = ::AppPerfRpm::Backtrace::Cleaner.new
          @backtrace_cleaner.add_filter   { |line| line.sub("#{::AppPerfRpm.app_root}/", '') }
          @backtrace_cleaner.add_filter   { |line| line.sub(RENDER_TEMPLATE_PATTERN, '') }
          @backtrace_cleaner.add_filter   { |line| line.sub('./', '/') }
          @backtrace_cleaner.add_gem_filters
          @backtrace_cleaner.add_silencer { |line| line !~ APP_DIRS_PATTERN }
        end
        @backtrace_cleaner
      end

      def source_extract(_backtrace = ::AppPerfRpm::Backtrace.application_trace)
        if(trace = _backtrace.first)
          file, line_number = extract_file_and_line_number(trace)

          {
            code: source_fragment(file, line_number),
            line_number: line_number
          }
        else
          nil
        end
      end

      def source_extracts(_backtrace = base_backtrace)
        _backtrace.map do |trace|
          file, line_number = extract_file_and_line_number(trace)

          {
            code: source_fragment(file, line_number),
            line_number: line_number
          }
        end
      end

      private

      def source_fragment(path, line)
        return unless Rails.respond_to?(:root) && Rails.root
        full_path = Rails.root.join(path)
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

      def trim_backtrace(_backtrace)
        return _backtrace unless _backtrace.is_a?(Array)

        length = _backtrace.size
        if length > 100
          # Trim backtraces by getting the first 180 and last 20 lines
          trimmed = _backtrace[0, 80] + ['...[snip]...'] + _backtrace[length - 20, 20]
        else
          trimmed = _backtrace
        end
        trimmed
      end
     end
  end
end

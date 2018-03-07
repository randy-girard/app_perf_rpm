require 'spec_helper'

describe AppPerfRpm::Utils do
  it "should log source and backtrace" do
    AppPerfRpm.config.instrumentation[:test] = {
      :backtrace => :all,
      :source => true
    }
    span = AppPerfRpm::Tracing::Span.new(nil, "operation", nil)
    expect(span).to receive(:log).with(
      event: "backtrace",
      stack: anything
    ).and_call_original
    expect(span).to receive(:log).with(
      event: "source",
      stack: anything
    ).and_call_original
    AppPerfRpm::Utils.log_source_and_backtrace(span, :test)
    expect(span.log_entries[1]["fields"][:stack][0..1]).to eql([
      {
        "file"=>"[APP_PATH]/lib/app_perf_rpm/backtrace.rb",
        "code"=>{
          48=>"\n",
          49=>"      def source_extract(opts = {})\n",
          50=>"        backtrace = opts[:backtrace] || Kernel.caller(0)\n",
          51=>"\n",
          52=>"        Array(backtrace).select {|bt| bt[/^\#{::AppPerfRpm.config.app_root.to_s}\\//] }.map do |trace|\n",
          53=>"          file, line_number = extract_file_and_line_number(trace)\n"
        },
        "line_number"=>50
      },
      {
        "file"=>"[APP_PATH]/lib/app_perf_rpm/utils.rb",
        "code"=>{
          36=>"      end\n",
          37=>"      if config[:source]\n",
          38=>"        source = AppPerfRpm::Backtrace.source_extract\n",
          39=>"        if source.length > 0\n",
          40=>"          span.log(event: \"source\", stack: source)\n",
          41=>"        end\n"
        },
        "line_number"=>38
      }
    ])
  end

  it "should not log source and backtrace" do
    AppPerfRpm.config.instrumentation[:test] = {
      :backtrace => false,
      :source => false
    }
    span = AppPerfRpm::Tracing::Span.new(nil, "operation", nil)
    expect(span).to receive(:log).with(
      event: "backtrace",
      stack: anything
    ).never
    expect(span).to receive(:log).with(
      event: "source",
      stack: anything
    ).never
    AppPerfRpm::Utils.log_source_and_backtrace(span, :test)

    expect(span.log_entries[0]).to eql(nil)
    expect(span.log_entries[1]).to eql(nil)
  end
end

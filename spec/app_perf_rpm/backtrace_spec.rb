require 'spec_helper'

describe AppPerfRpm::Backtrace do
  it "should not return backtrace" do
    backtrace = AppPerfRpm::Backtrace.backtrace({ :kind => nil })
    expect(backtrace).to eql(nil)
  end

  it "should return backtrace with app only" do
    backtrace = AppPerfRpm::Backtrace.backtrace(kind: :app)
    expect(backtrace.first).to eql("[APP_PATH]/spec/app_perf_rpm/backtrace_spec.rb:10:in `block (2 levels) in <top (required)>'")
  end

  it "should return source for app" do
    expect(AppPerfRpm::Backtrace.source_extract[0..1]).to eql([
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
        "file"=>"[APP_PATH]/spec/app_perf_rpm/backtrace_spec.rb",
        "code"=>{
          13=>"\n",
          14=>"  it \"should return source for app\" do\n",
          15=>"    expect(AppPerfRpm::Backtrace.source_extract[0..1]).to eql([\n",
          16=>"      {\n",
          17=>"        \"file\"=>\"[APP_PATH]/lib/app_perf_rpm/backtrace.rb\",\n",
          18=>"        \"code\"=>{\n"
        },
        "line_number"=>15
      }
    ])
  end
end

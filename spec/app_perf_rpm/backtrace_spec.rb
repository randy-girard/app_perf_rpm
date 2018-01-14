require 'spec_helper'

describe AppPerfRpm::Backtrace do
  it "should not return backtrace" do
    backtrace = AppPerfRpm::Backtrace.backtrace(kind: nil)
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
          45=>"      #end\n",
          46=>"\n",
          47=>"      def source_extract(opts = { :backtrace => Kernel.caller(0) })\n",
          48=>"        backtrace = opts[:backtrace]\n",
          49=>"\n",
          50=>"        Array(backtrace).select {|bt| bt[/^\#{::AppPerfRpm.config.app_root.to_s}\\//] }.map do |trace|\n"
        },
        "line_number"=>47
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

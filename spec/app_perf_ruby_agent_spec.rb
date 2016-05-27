require 'spec_helper'

describe AppPerfRubyAgent do

  subject { AppPerfRubyAgent }

  describe "#host" do
    it "returns the host name" do
      expect(Socket).to receive(:gethostname) { "host" }
      expect(subject.host).to eq("host")
    end
  end

  describe "#round_time" do
    it "returns rounded time" do
      actual = Time.parse("2016-01-01 12:00:30")
      expected = Time.parse("2016-01-01 12:01:00")
      result = Time.parse(subject.round_time(actual, 60))
      expect(result).to eq(expected)
    end
  end

  describe "#clean_trace" do
    it "returns cleaned trace" do
      expect(subject).to receive(:caller) {
        [
          "example.rb:236:in `instance_exec'",
          "example.rb:236:in `block in run'",
          "example.rb:478:in `block in with_around_and_singleton_context_hooks'",
          "example.rb:435:in `block in with_around_example_hooks'",
          "hooks.rb:478:in `block in run'",
          "hooks.rb:616:in `run_around_example_hooks_for'"
        ]
      }
      expect(subject.clean_trace).to eq([])
    end
  end

  describe "#collection_on" do
    it "should turn collecting on" do
      Thread.current[:app_perf_collecting] = false
      subject.collection_on
      expect(Thread.current[:app_perf_collecting]).to eq(true)
    end
  end

  describe "#collection_off" do
    it "should turn collecting off" do
      Thread.current[:app_perf_collecting] = true
      subject.collection_off
      expect(Thread.current[:app_perf_collecting]).to eq(false)
    end
  end

  describe "#collecting?" do
    it "should be collecting" do
      Thread.current[:app_perf_collecting] = true
      expect(subject.collecting?).to eq(true)
    end
  end


end

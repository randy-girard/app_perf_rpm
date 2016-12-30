require 'spec_helper'

describe AppPerfRpm do

  subject { AppPerfRpm }

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
    it "returns cleaned trace with app marked" do
      dir = File.dirname(__FILE__)
      expect(Kernel).to receive(:caller) {
        [
          "#{dir}/example.rb:236:in `instance_exec'",
          "#{dir}/example.rb:236:in `block in run'",
          "#{dir}/example.rb:478:in `block in with_around_and_singleton_context_hooks'",
          "#{dir}/example.rb:435:in `block in with_around_example_hooks'",
          "#{dir}/hooks.rb:478:in `block in run'",
          "#{dir}/hooks.rb:616:in `run_around_example_hooks_for'"
        ]
      }
      expect(subject.clean_trace).to eq([
        "*#{dir}/example.rb:236:in `instance_exec'",
        "*#{dir}/example.rb:236:in `block in run'",
        "*#{dir}/example.rb:478:in `block in with_around_and_singleton_context_hooks'",
        "*#{dir}/example.rb:435:in `block in with_around_example_hooks'",
        "*#{dir}/hooks.rb:478:in `block in run'",
        "*#{dir}/hooks.rb:616:in `run_around_example_hooks_for'"])
    end

    it "returns cleaned trace without app marked" do
      dir = File.dirname(__FILE__)
      expect(Kernel).to receive(:caller) {
        [
          "example.rb:236:in `instance_exec'",
          "example.rb:236:in `block in run'",
          "example.rb:478:in `block in with_around_and_singleton_context_hooks'",
          "example.rb:435:in `block in with_around_example_hooks'",
          "hooks.rb:478:in `block in run'",
          "hooks.rb:616:in `run_around_example_hooks_for'"
        ]
      }
      expect(subject.clean_trace).to eq([
        "example.rb:236:in `instance_exec'",
        "example.rb:236:in `block in run'",
        "example.rb:478:in `block in with_around_and_singleton_context_hooks'",
        "example.rb:435:in `block in with_around_example_hooks'",
        "hooks.rb:478:in `block in run'",
        "hooks.rb:616:in `run_around_example_hooks_for'"])
    end
  end

  describe "#tracing on" do
    it "should turn tracing on" do
      expect(::AppPerfRpm).to receive(:mutex) { Mutex.new }.twice

      ::AppPerfRpm.tracing_off

      subject.tracing_on
      expect(subject.tracing?).to eq(true)
    end
  end

  describe "#collection_off" do
    it "should turn collecting off" do
      expect(::AppPerfRpm).to receive(:mutex) { Mutex.new }.twice
      ::AppPerfRpm.tracing_on

      subject.tracing_off
      expect(subject.tracing?).to eq(false)
    end
  end

  describe "#collecting?" do
    it "should be collecting" do
      expect(::AppPerfRpm).to receive(:mutex) { Mutex.new }.once

      ::AppPerfRpm.tracing_on
      expect(subject.tracing?).to eq(true)
    end
  end


end

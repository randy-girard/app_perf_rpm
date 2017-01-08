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

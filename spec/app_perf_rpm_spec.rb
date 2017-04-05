require 'spec_helper'
require 'socket'

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

  describe ".load" do 
    context "agent classes and worker" do
      it "should not load" do
        worker = double('AppPerfRpm::Worker', start: {})
        expect(::AppPerfRpm).to receive(:disable_agent?).and_return(true)
        expect(worker).to_not receive(:start)

        ::AppPerfRpm.load
      end
      it "should load" do
        worker = double('AppPerfRpm::Worker', start: {})
        expect(::AppPerfRpm).to receive(:disable_agent?).and_return(false)
        expect(::AppPerfRpm::Worker).to receive(:new).and_return(worker)
        expect(worker).to receive(:start)

        ::AppPerfRpm.load
      end
    end
  end

  describe ".disable_agent?" do 
    subject { ::AppPerfRpm.disable_agent? } 

    context "using configuration" do
      it "and disabled" do
        expect(AppPerfRpm.configuration).to receive(:agent_disabled).and_return(true)
        expect(AppPerfRpm::Introspector).to receive(:agentable?).and_return(true)
        expect(subject).to eq(true)
      end
      it "and defaults" do 
        expect(AppPerfRpm.configuration).to receive(:agent_disabled).and_return(false)
        expect(AppPerfRpm::Introspector).to receive(:agentable?).and_return(true)
        expect(subject).to eq(false)
      end
    end

    context "using IntroSpector" do 
      it "invalid runner" do
        hide_const("Puma")
        expect(subject).to eq(false)
      end
      it "valid runner" do
        expect(AppPerfRpm.configuration).to receive(:agent_disabled).and_return(false)
        stub_const("Puma",{})
        expect(subject).to eq(false)
      end
    end

  end #describe 
end

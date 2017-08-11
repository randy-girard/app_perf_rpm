require 'spec_helper'

describe AppPerfRpm do

  subject { AppPerfRpm::Tracer }

  class MockWorker
    attr_accessor :spans

    def initialize
      @spans = []
    end
    def save(span)
      @spans << span
    end
  end

=begin
  it "does stuff" do
    worker = MockWorker.new
    AppPerfRpm.instance_variable_set(:@worker_running, true)
    AppPerfRpm.instance_variable_set(:@worker, worker)
    AppPerfRpm.instance_variable_set(:@tracing, true)

    subject.start_trace("1_first", { "trace_id" => 1 }) do
      subject.trace("1_second", {}) do
        subject.trace("1_third", {}) do
          sleep 1
        end
      end
    end
    subject.start_trace("2_first", { "trace_id" => 2 }) do
      subject.trace("2_second", {}) do
        subject.trace("2_third", {}) do
          sleep 2
        end
      end
    end

    #worker.spans.group_by(&:trace_id).map{|a| puts a.last.inspect }
    traces = worker.spans.group_by(&:trace_id).map{|a| AppPerfRpm::Span.arrange(a.last) }

    traces
      .group_by {|span| AppPerfRpm.floor_time(Time.at(span.started_at), 1) }
      .map {|traces| traces.last }
      .flatten
      .map {|traces| traces.to_spans }
      .flatten
      .map {|span| puts span.inspect; span }
      .each {|s| puts s.to_a.inspect }

  end
=end
  context "trace header is set" do
    it "should trace with that trace key" do
      allow(Time).to receive(:now) { 0 }
      worker = MockWorker.new
      allow(::AppPerfRpm::Backtrace).to receive(:source_extract) { "source" }
      AppPerfRpm.instance_variable_set(:@worker_running, true)
      AppPerfRpm.instance_variable_set(:@worker, worker)
      AppPerfRpm.instance_variable_set(:@tracing, true)

      subject.start_trace("first", { "trace_id" => 1 }) do
        subject.trace("second", {}) do
          subject.trace("third", {}) do

          end
        end
      end

      expect(worker.spans.map(&:to_a)).to eql([
        ["third", 1, 0.0, 0.0, {"type"=>"web", "source"=>"source"}],
        ["second", 1, 0.0, 0.0, {"type"=>"web", "source"=>"source"}],
        ["first", 1, 0.0, 0.0, {"type"=>"web", "source"=>"source"}]
      ])
    end
  end

  context "when sample rate is 100" do
    before do
      ::AppPerfRpm.configure do |config|
        config.sample_rate = 100
      end
      ::AppPerfRpm.load
    end

    it "should want to trace" do
      expect(subject.should_trace?).to eql(true)
    end

    it "should trace through all traces" do
      allow(Time).to receive(:now) { 0 }
      worker = MockWorker.new
      allow(::AppPerfRpm::Backtrace).to receive(:source_extract) { "source" }
      AppPerfRpm.instance_variable_set(:@worker_running, true)
      AppPerfRpm.instance_variable_set(:@worker, worker)
      AppPerfRpm.instance_variable_set(:@tracing, true)

      subject.start_trace("first", { "trace_id" => 1 }) do
        subject.trace("second", {}) do
          subject.trace("third", {}) do

          end
        end
      end

      expect(worker.spans.map(&:to_a)).to eql([
        ["third", 1, 0.0, 0.0, {"type"=>"web", "source"=>"source"}],
        ["second", 1, 0.0, 0.0, {"type"=>"web", "source"=>"source"}],
        ["first", 1, 0.0, 0.0, {"type"=>"web", "source"=>"source"}]
      ])
    end
  end

  context "when sample rate is not 100" do
    before do
      ::AppPerfRpm.configure do |config|
        config.sample_rate = 50
      end
      ::AppPerfRpm.load
    end

    it "should only trace some times" do
      expect(subject).to receive(:random_percentage).once { 49 }
      expect(subject).to receive(:random_percentage).once { 51 }
      expect(subject.should_trace?).to eql(true)
      expect(subject.should_trace?).to eql(false)
    end

    it "should trace some times" do
      expect(subject).to receive(:random_percentage).once { 49 }
      expect(subject).to receive(:random_percentage).once { 51 }
      allow(Time).to receive(:now) { 0 }
      expect(Digest::SHA1).to receive(:hexdigest) { 1 }
      worker = MockWorker.new
      allow(::AppPerfRpm::Backtrace).to receive(:source_extract) { "source" }
      AppPerfRpm.instance_variable_set(:@worker_running, true)
      AppPerfRpm.instance_variable_set(:@worker, worker)
      AppPerfRpm.instance_variable_set(:@tracing, true)

      subject.start_trace("first", {}) do
        subject.trace("second", {}) do
          subject.trace("third", {}) do
          end
        end
      end

      subject.start_trace("first", {}) do
        subject.trace("second", {}) do
          subject.trace("third", {}) do
          end
        end
      end

      expect(worker.spans.map(&:to_a)).to eql([
        ["third", 1, 0.0, 0.0, {"type"=>"web", "source"=>"source"}],
        ["second", 1, 0.0, 0.0, {"type"=>"web", "source"=>"source"}],
        ["first", 1, 0.0, 0.0, {"type"=>"web", "source"=>"source"}]
      ])
    end
  end
end

require 'spec_helper'

describe AppPerfRpm do

  subject { AppPerfRpm::Tracer }

  context "trace header is set" do
    it "should trace with that trace key" do
      allow(Time).to receive(:now) { 0 }
      expect(::AppPerfRpm).to receive(:store).with(["third", 1, 0.0, 0.0, "--- {}\n"]).once
      expect(::AppPerfRpm).to receive(:store).with(["second", 1, 0.0, 0.0, "--- {}\n"]).once
      expect(::AppPerfRpm).to receive(:store).with(["first", 1, 0.0, 0.0, "--- {}\n"]).once

      subject.start_trace("first", { :trace_id => 1 }) do
        subject.trace("second", {}) do
          subject.trace("third", {}) do

          end
        end
      end
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
      expect(::AppPerfRpm).to receive(:store).with(["third", 1, 0.0, 0.0, "--- {}\n"]).once
      expect(::AppPerfRpm).to receive(:store).with(["second", 1, 0.0, 0.0, "--- {}\n"]).once
      expect(::AppPerfRpm).to receive(:store).with(["first", 1, 0.0, 0.0, "--- {}\n"]).once

      subject.start_trace("first", { :trace_id => 1 }) do
        subject.trace("second", {}) do
          subject.trace("third", {}) do

          end
        end
      end
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
      expect(::AppPerfRpm).to receive(:store).with(["third", 1, 0.0, 0.0, "--- {}\n"]).once
      expect(::AppPerfRpm).to receive(:store).with(["second", 1, 0.0, 0.0, "--- {}\n"]).once
      expect(::AppPerfRpm).to receive(:store).with(["first", 1, 0.0, 0.0, "--- {}\n"]).once

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
    end
  end
end

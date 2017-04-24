require 'spec_helper'

describe AppPerfRpm do
  subject { AppPerfRpm::Introspector.agentable? }
  context "AppPerfRpm::Introspector.agentable?" do

    let(:runner) { AppPerfRpm::Introspector::VALID_RUNNERS.sample.to_s }

    context "no valid runner" do
      it "returns false" do
        expect(subject).to eq(false)
      end
    end
    context "valid runner" do
      it "returns true" do
        expect(AppPerfRpm::Introspector).to receive(:rspecing?).and_return(false)
        stub_const(runner,{})
        expect(subject).to eq(true)
      end
    end
  end
end

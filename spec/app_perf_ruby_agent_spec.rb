require 'spec_helper'

describe AppPerfRubyAgent do

  subject { AppPerfRubyAgent }

  it "returns the host name" do
    expect(Socket).to receive(:gethostname) { "host" }
    expect(subject.host).to eq("host")
  end
end

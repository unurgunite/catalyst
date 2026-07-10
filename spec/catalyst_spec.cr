require "./spec_helper"

describe Catalyst do
  it "has a version number" do
    Catalyst::VERSION.should_not be_nil
  end

  it "loads config without file" do
    config = Catalyst::Config.load("/nonexistent/.catalyst.yml")
    config.severity.should eq("warning")
  end
end

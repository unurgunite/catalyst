require "./spec_helper"

describe Catalyst do
  it "has a version number" do
    Catalyst::VERSION.should_not be_nil
  end

  it "loads config without file" do
    config = Catalyst::Config.load("/nonexistent/.catalyst.yml")
    config.severity.should eq("warning")
  end

  it "refuses to run with an empty rule registry" do
    saved = Catalyst::Rule.all.dup
    begin
      Catalyst::Rule.all.clear
      Catalyst::CLI.run(["src/"]).should eq(2)
    ensure
      Catalyst::Rule.all.concat(saved)
    end
  end
end

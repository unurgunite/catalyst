require "../spec_helper"

module Catalyst
  describe Config do
    describe ".load" do
      it "falls back to default when file is missing" do
        config = Config.load("nonexistent-catalyst.yml")
        config.severity.should eq("warning")
        config.rules.should be_empty
      end

      it "parses a valid config file" do
        path = File.tempfile("catalyst-config", ".yml") do |file|
          file.print("severity: info\nformat: json\nrules:\n  CAT-004:\n    enabled: false\nignore: []\npaths: []\n")
        end.path
        begin
          config = Config.load(path)
          config.severity.should eq("info")
          config.rules["CAT-004"].enabled?.should be_false
        ensure
          File.delete(path) if File.exists?(path)
        end
      end

      it "raises ConfigError with path and hint on malformed rules" do
        path = File.tempfile("catalyst-config", ".yml") do |file|
          file.print("severity: warning\nformat: terminal\nrules:\n  CAT-001: true\nignore: []\npaths: []\n")
        end.path
        begin
          ex = expect_raises(ConfigError) { Config.load(path) }
          ex.message.to_s.should contain(path)
          ex.message.to_s.should contain("enabled")
          ex.message.to_s.should_not contain("Unhandled exception")
        ensure
          File.delete(path) if File.exists?(path)
        end
      end
    end
  end
end

require "../spec_helper"

module Catalyst
  describe Config do
    describe ".load" do
      it "fills every unset key with defaults" do
        temp_dir do |dir|
          path = write(dir, ".catalyst.yml", "severity: info\n")
          config = Catalyst::Config.load(path)
          config.severity.should eq("info")
          config.format.should eq("terminal")
          config.rules.should be_empty
          config.ignore.should be_empty
        end
      end

      it "rejects an unknown severity" do
        temp_dir do |dir|
          path = write(dir, ".catalyst.yml", "severity: fatal\n")
          ex = expect_raises(Catalyst::ConfigError) { Catalyst::Config.load(path) }
          ex.message.to_s.should contain("severity")
          ex.message.to_s.should contain("error|warning|info|hint")
        end
      end

      it "rejects an unknown format" do
        temp_dir do |dir|
          path = write(dir, ".catalyst.yml", "format: yaml\n")
          expect_raises(Catalyst::ConfigError) { Catalyst::Config.load(path) }
        end
      end

      it "rejects an unknown rule id instead of ignoring it" do
        temp_dir do |dir|
          path = write(dir, ".catalyst.yml", "rules:\n  CAT-999:\n    enabled: false\n")
          ex = expect_raises(Catalyst::ConfigError) { Catalyst::Config.load(path) }
          ex.message.to_s.should contain("CAT-999")
        end
      end

      it "rejects an invalid per-rule severity" do
        temp_dir do |dir|
          path = write(dir, ".catalyst.yml", "rules:\n  CAT-001:\n    severity: loud\n")
          expect_raises(Catalyst::ConfigError) { Catalyst::Config.load(path) }
        end
      end

      it "keeps rule params" do
        temp_dir do |dir|
          path = write(dir, ".catalyst.yml", "rules:\n  CAT-016:\n    params:\n      threshold: 6\n")
          config = Catalyst::Config.load(path)
          (config.rules["CAT-016"].params || {} of String => YAML::Any)["threshold"].as_i.should eq(6)
        end
      end

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

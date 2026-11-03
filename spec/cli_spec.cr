require "./spec_helper"

describe Catalyst::CLI do
  it "validates severity before running" do
    Catalyst::CLI.run(["--severity", "fatal", "src"]).should eq(2)
  end

  it "validates format before running" do
    Catalyst::CLI.run(["--format", "yaml", "src"]).should eq(2)
  end

  it "returns 2 for an unknown option instead of a stacktrace" do
    Catalyst::CLI.run(["--definitely-not-a-flag"]).should eq(2)
  end

  it "returns 0 for --version without exiting the process" do
    Catalyst::CLI.run(["--version"]).should eq(0)
  end

  it "returns 0 for --help without exiting the process" do
    Catalyst::CLI.run(["--help"]).should eq(0)
  end

  # `Config` is a struct, so an override applied to a copy is silently lost.
  # Asserting the resolved value is what catches that; asserting the exit
  # code of a full run would pass even with the flag ignored.
  it "lets --format override the config file" do
    options = Catalyst::Options.new
    options.format = "json"
    config = Catalyst::CLI.apply_overrides_for_test(Catalyst::Config.default, options)
    config.should_not be_nil
    config.try(&.format).should eq("json")
  end

  it "lets --severity override the config file" do
    options = Catalyst::Options.new
    options.min_severity = "hint"
    config = Catalyst::CLI.apply_overrides_for_test(Catalyst::Config.default, options)
    config.should_not be_nil
    config.try(&.severity).should eq("hint")
  end

  it "returns 2 when an input path does not exist" do
    temp_dir do |dir|
      config = write(dir, ".catalyst.yml", "severity: warning\nformat: terminal\n")
      Catalyst::CLI.run(["--config", config, File.join(dir, "missing.cr")]).should eq(2)
    end
  end

  it "returns 2 for a corrupt baseline" do
    temp_dir do |dir|
      config = write(dir, ".catalyst.yml", "severity: warning\nformat: terminal\n")
      baseline = write(dir, "bad.json", "{")
      source = write(dir, "a.cr", "[3, 1].sort.first\n")
      Catalyst::CLI.run(["--config", config, "--baseline", baseline, source]).should eq(2)
    end
  end

  # The exit code and the report must agree on what counts as a finding.
  # Severity filtering used to run inside the formatters only, so `--ci` at a
  # severity above the findings' own exited 1 while printing nothing at all.
  describe "--ci" do
    it "exits 0 when every finding is below the minimum severity" do
      temp_dir do |dir|
        config = write(dir, ".catalyst.yml", "severity: error\nformat: terminal\n")
        # CAT-041 is info, so an error-level gate has nothing to report.
        source = write(dir, "a.cr", "def f(urls)\n  urls.each { |u| URI.parse(u) }\nend\n")
        Catalyst::CLI.run(["--config", config, "--ci", source]).should eq(0)
      end
    end

    it "exits 1 when a finding meets the minimum severity" do
      temp_dir do |dir|
        config = write(dir, ".catalyst.yml", "severity: hint\nformat: terminal\n")
        source = write(dir, "a.cr", "def f(urls)\n  urls.each { |u| URI.parse(u) }\nend\n")
        Catalyst::CLI.run(["--config", config, "--ci", source]).should eq(1)
      end
    end
  end
end

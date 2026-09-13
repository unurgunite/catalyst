require "./spec_helper"

private def run_on_fixture(code : String, config : Catalyst::Config = Catalyst::Config.default, options : Catalyst::Options = Catalyst::Options.new) : Array(Catalyst::Result)
  dir = File.join(Dir.tempdir, "catalyst_spec_#{Random.rand(1_000_000_000)}")
  Dir.mkdir_p(dir)
  path = File.join(dir, "sample.cr")
  begin
    File.write(path, code)
    Catalyst::Runner.new(config, options).run([path])
  ensure
    File.delete(path) if File.exists?(path)
    Dir.delete(dir) if Dir.exists?(dir)
  end
end

private def config_with_rules(rules_yaml : String) : Catalyst::Config
  Catalyst::Config.from_yaml("severity: warning\nformat: terminal\nrules:\n#{rules_yaml}ignore: []\npaths: []\n")
end

FIXTURE_CODE = "list = [9, 8, 7, 6, 5, 4, 3, 2, 1]\n[3, 1, 2].sort.first\nitems.each { |i| list.includes?(i) }\n"

describe Catalyst::Runner do
  it "runs all rules by default" do
    ids = run_on_fixture(FIXTURE_CODE).map(&.rule_id).to_set
    ids.should contain("CAT-001")
    ids.should contain("CAT-004")
  end

  it "honors --rules allowlist" do
    options = Catalyst::Options.new
    options.rules = ["CAT-001"]
    ids = run_on_fixture(FIXTURE_CODE, options: options).map(&.rule_id).to_set
    ids.should contain("CAT-001")
    ids.should_not contain("CAT-004")
  end

  it "honors --ignore denylist" do
    options = Catalyst::Options.new
    options.ignore = ["CAT-004"]
    ids = run_on_fixture(FIXTURE_CODE, options: options).map(&.rule_id).to_set
    ids.should contain("CAT-001")
    ids.should_not contain("CAT-004")
  end

  it "honors config.rules enabled flag" do
    config = config_with_rules("  CAT-004:\n    enabled: false\n")
    ids = run_on_fixture(FIXTURE_CODE, config).map(&.rule_id).to_set
    ids.should contain("CAT-001")
    ids.should_not contain("CAT-004")
  end

  it "honors config.rules severity override" do
    config = config_with_rules("  CAT-001:\n    severity: error\n")
    results = run_on_fixture(FIXTURE_CODE, config)
    cat001 = results.select { |result| result.rule_id == "CAT-001" }
    cat001.should_not be_empty
    cat001.each(&.severity.should(eq("error")))
  end

  it "falls back to config.paths when no CLI paths given" do
    dir = File.join(Dir.tempdir, "catalyst_spec_#{Random.rand(1_000_000_000)}")
    Dir.mkdir_p(dir)
    begin
      File.write(File.join(dir, "sample.cr"), FIXTURE_CODE)
      # Escape backslashes: raw Windows temp paths break YAML double quotes.
      yaml_dir = dir.gsub("\\", "\\\\")
      config = Catalyst::Config.from_yaml(<<-YAML)
        severity: warning
        format: terminal
        rules: {}
        ignore: []
        paths: ["#{yaml_dir}"]
        YAML
      ids = Catalyst::Runner.new(config, Catalyst::Options.new).run([] of String).map(&.rule_id).to_set
      ids.should contain("CAT-001")
    ensure
      File.delete(File.join(dir, "sample.cr")) if File.exists?(File.join(dir, "sample.cr"))
      Dir.delete(dir) if Dir.exists?(dir)
    end
  end
end

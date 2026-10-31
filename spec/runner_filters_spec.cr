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
  describe "rule params" do
    it "lets config override a rule threshold" do
      temp_dir do |dir|
        code = "def f : String | Int32 | Bool | Nil\n  nil\nend\n"
        path = write(dir, "u.cr", code)
        options = Catalyst::Options.new
        options.rules = ["CAT-016"]

        low = full_config("  CAT-016:\n    params:\n      threshold: 3\n")
        Catalyst::Runner.new(low, options).run([path]).size.should eq(1)

        high = full_config("  CAT-016:\n    params:\n      threshold: 9\n")
        Catalyst::Runner.new(high, options).run([path]).size.should eq(0)
      end
    end
  end

  describe "opt-in rules" do
    it "excludes them by default" do
      temp_dir do |dir|
        path = write(dir, "t.cr", "Thread.new { work }\n")
        Catalyst::Runner.new(full_config, Catalyst::Options.new).run([path]).size.should eq(0)
      end
    end

    it "reaches them through --rules" do
      temp_dir do |dir|
        path = write(dir, "t.cr", "Thread.new { work }\n")
        options = Catalyst::Options.new
        options.rules = ["CAT-049"]
        ids = Catalyst::Runner.new(full_config, options).run([path]).map(&.rule_id)
        ids.should contain("CAT-049")
      end
    end

    it "re-reaches them through config enabled: true" do
      temp_dir do |dir|
        path = write(dir, "t.cr", "Thread.new { work }\n")
        config = full_config("  CAT-049:\n    enabled: true\n")
        ids = Catalyst::Runner.new(config, Catalyst::Options.new).run([path]).map(&.rule_id)
        ids.should contain("CAT-049")
      end
    end
  end

  describe "file collection" do
    it "analyzes an overlapping file only once" do
      temp_dir do |dir|
        path = write(dir, "a.cr", "[3, 1].sort.first\n")
        results = Catalyst::Runner.new(full_config, Catalyst::Options.new).run([dir, path])
        results.count { |result| result.rule_id == "CAT-001" }.should eq(1)
      end
    end

    it "counts a missing path as an error" do
      runner = Catalyst::Runner.new(full_config, Catalyst::Options.new)
      runner.run(["/nonexistent/definitely-missing.cr"])
      runner.errors.should eq(1)
    end

    it "counts a parse error as an error" do
      temp_dir do |dir|
        path = write(dir, "bad.cr", "def (\n")
        runner = Catalyst::Runner.new(full_config, Catalyst::Options.new)
        runner.run([path])
        runner.errors.should eq(1)
      end
    end
  end

  describe "--fix safety" do
    it "never writes a rewrite that does not parse" do
      temp_dir do |dir|
        path = write(dir, "a.cr", "class Foo\n  Regex.new(\"user-id\")\nend\n")
        options = Catalyst::Options.new
        options.fix = true
        Catalyst::Runner.new(full_config, options).run([path])

        fixed = File.read(path)
        fixed.should contain("USER_ID = Regex.new(\"user-id\")")
        # The rewritten file must still compile.
        Crystal::Parser.new(fixed).parse
      end
    end

    it "does not define an undefined bare constant" do
      temp_dir do |dir|
        path = write(dir, "b.cr", "class Foo\n  Regex.new(\"user-id\")\nend\n")
        options = Catalyst::Options.new
        options.fix = true
        Catalyst::Runner.new(full_config, options).run([path])
        File.read(path).each_line do |line|
          stripped = line.strip
          next if stripped.includes?("class") || stripped == "end"
          # Any emitted fix must keep the constructor visible on the line.
          stripped.should contain("Regex.new")
        end
      end
    end

    it "writes nothing in --dry-run mode" do
      temp_dir do |dir|
        original = "class Foo\n  Regex.new(\"user-id\")\nend\n"
        path = write(dir, "c.cr", original)
        options = Catalyst::Options.new
        options.fix = true
        options.dry_run = true
        Catalyst::Runner.new(full_config, options).run([path])

        File.read(path).should eq(original)
        File.exists?("#{path}.bak").should be_false
      end
    end

    it "never overwrites an existing backup" do
      temp_dir do |dir|
        path = write(dir, "d.cr", "class Foo\n  Regex.new(\"user-id\")\nend\n")
        File.write("#{path}.bak", "ORIGINAL BACKUP")
        options = Catalyst::Options.new
        options.fix = true
        Catalyst::Runner.new(full_config, options).run([path])

        File.read("#{path}.bak").should eq("ORIGINAL BACKUP")
      end
    end

    it "preserves the trailing newline" do
      temp_dir do |dir|
        path = write(dir, "e.cr", "class Foo\n  Regex.new(\"user-id\")\nend\n")
        options = Catalyst::Options.new
        options.fix = true
        Catalyst::Runner.new(full_config, options).run([path])
        File.read(path).should end_with("\n")
      end
    end
  end
end

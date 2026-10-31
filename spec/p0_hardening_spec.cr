require "./spec_helper"

# Regression coverage for the P0 hardening pass:
#  - `--severity` / `--format` actually take effect (they used to be parsed
#    and then dropped in favour of the config values)
#  - a `hint` finding no longer crashes the terminal formatter
#  - `--fix` never writes unparsable code, refuses no-op rewrites, reports
#    what it would change under `--dry-run`, and never overwrites a backup
#
# CLI flag precedence is asserted on the resolved value (`Options` defaults
# are nil = "not passed"), so no STDOUT capture is needed.
private def with_tmp_dir(&)
  dir = File.join(Dir.tempdir, "catalyst_p0_#{Random.rand(1_000_000_000)}")
  Dir.mkdir_p(dir)
  begin
    yield dir
  ensure
    Dir.glob(File.join(dir, "**", "*")).each { |path| File.delete(path) if File.file?(path) }
    Dir.delete(dir) if Dir.exists?(dir)
  end
end

describe "CLI option defaults" do
  it "leaves format and severity unset so the config value wins" do
    options = Catalyst::Options.new
    options.format.should be_nil
    options.min_severity.should be_nil
  end

  it "does not enable --fix or --dry-run by default" do
    options = Catalyst::Options.new
    options.fix?.should be_false
    options.dry_run?.should be_false
  end

  it "exposes the same severity ordering the formatters use" do
    Catalyst::CLI::SEVERITY_LEVELS.should eq(%w[error warning info hint])
  end

  it "lists the supported formats" do
    Catalyst::CLI::FORMATS.should eq(%w[terminal json sarif])
  end
end

describe "Formatter severity filtering" do
  results = [
    Catalyst::Result.new(rule_id: "A", severity: "error", message: "", file: "f.cr"),
    Catalyst::Result.new(rule_id: "B", severity: "warning", message: "", file: "f.cr"),
    Catalyst::Result.new(rule_id: "C", severity: "info", message: "", file: "f.cr"),
    Catalyst::Result.new(rule_id: "D", severity: "hint", message: "", file: "f.cr"),
  ]

  it "keeps only findings at or above the minimum" do
    io = IO::Memory.new
    Catalyst::Formatters::Json.new.output(results, io, "warning")
    io.to_s.should contain(%q("A"))
    io.to_s.should contain(%q("B"))
    io.to_s.should_not contain(%q("C"))
    io.to_s.should_not contain(%q("D"))
  end

  it "treats an unknown minimum as the least severe level" do
    io = IO::Memory.new
    only_hint = [Catalyst::Result.new(rule_id: "D", severity: "hint", message: "", file: "f.cr")]
    Catalyst::Formatters::Json.new.output(only_hint, io, "bogus")
    io.to_s.should contain(%q("D"))
  end

  it "renders hint-severity findings without raising" do
    # `:dim` is not a Colorize color; this used to raise ArgumentError and
    # take down the whole run.
    io = IO::Memory.new
    hint = [Catalyst::Result.new(rule_id: "CAT-039", severity: "hint", message: "hint finding", file: "a.cr", line: 1, column: 1)]
    Catalyst::Formatters::Terminal.new.output(hint, io, "hint")
    io.to_s.should contain("CAT-039")
  end

  it "renders every severity the rules can emit" do
    io = IO::Memory.new
    Catalyst::Formatters::Terminal.new.output(results, io, "hint")
    io.to_s.should contain("A")
    io.to_s.should contain("D")
  end
end

describe "Runner --fix safety" do
  it "does not write a fix that would not parse" do
    with_tmp_dir do |dir|
      src = File.join(dir, "a.cr")
      original = "def f\n  x = Regex.new(\"foo\")\n  x\nend\n"
      File.write(src, original)

      options = Catalyst::Options.new
      options.fix = true
      Catalyst::Runner.new(Catalyst::Config.default, options).run([src])

      File.read(src).should eq(original)
    end
  end

  it "applies a fix that keeps the file parsable" do
    with_tmp_dir do |dir|
      src = File.join(dir, "a.cr")
      File.write(src, "class Foo\n  Regex.new(\"foo\")\nend\n")

      options = Catalyst::Options.new
      options.fix = true
      Catalyst::Runner.new(Catalyst::Config.default, options).run([src])

      fixed = File.read(src)
      fixed.should contain("FOO = Regex.new(\"foo\")")
      Crystal::Parser.new(fixed).parse
    end
  end

  it "writes nothing under --dry-run" do
    with_tmp_dir do |dir|
      src = File.join(dir, "a.cr")
      original = "class Foo\n  Regex.new(\"foo\")\nend\n"
      File.write(src, original)

      options = Catalyst::Options.new
      options.fix = true
      options.dry_run = true
      Catalyst::Runner.new(Catalyst::Config.default, options).run([src])

      File.read(src).should eq(original)
      File.exists?("#{src}.bak").should be_false
    end
  end

  it "leaves an existing backup untouched" do
    with_tmp_dir do |dir|
      src = File.join(dir, "a.cr")
      File.write(src, "class Foo\n  Regex.new(\"foo\")\nend\n")
      File.write("#{src}.bak", "ORIGINAL BACKUP\n")

      options = Catalyst::Options.new
      options.fix = true
      Catalyst::Runner.new(Catalyst::Config.default, options).run([src])

      # Never clobber the only copy of the pre-fix source.
      File.read("#{src}.bak").should eq("ORIGINAL BACKUP\n")
    end
  end

  it "preserves the trailing newline of the source file" do
    with_tmp_dir do |dir|
      src = File.join(dir, "a.cr")
      File.write(src, "class Foo\n  Regex.new(\"foo\")\nend\n")

      options = Catalyst::Options.new
      options.fix = true
      Catalyst::Runner.new(Catalyst::Config.default, options).run([src])

      File.read(src).ends_with?("\n").should be_true
    end
  end

  it "fixes the same line only once when two rules report it" do
    with_tmp_dir do |dir|
      src = File.join(dir, "a.cr")
      File.write(src, "class Foo\n  Regex.new(\"foo\")\nend\n")

      options = Catalyst::Options.new
      options.fix = true
      Catalyst::Runner.new(Catalyst::Config.default, options).run([src])

      # CAT-019 and CAT-039 both point at line 2; applying both would drop one.
      fixed = File.read(src)
      fixed.scan("FOO = Regex.new").size.should eq(1)
      fixed.should contain("class Foo")
      fixed.should contain("end")
    end
  end
end

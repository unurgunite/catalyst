require "../spec_helper"

private def finding(rule_id : String, severity : String, line : Int32) : Catalyst::Result
  Catalyst::Result.new(rule_id: rule_id, severity: severity, message: "message", file: "sample.cr", line: line, column: 1)
end

describe Catalyst::Formatters do
  # Severity filtering used to be reimplemented per formatter, with the
  # comparison inverted: a `min_severity` of warning dropped `error` findings
  # and kept only info/hint. These pin the corrected ordering.

  it "keeps only findings at the minimum severity" do
    results = [finding("CAT-013", "error", 1), finding("CAT-017", "hint", 2)]
    io = IO::Memory.new
    Catalyst::Formatter.for("json").output(results, io, "error")
    io.to_s.should contain("CAT-013")
    io.to_s.should_not contain("CAT-017")
  end

  it "keeps error findings above the minimum" do
    results = [finding("CAT-013", "error", 1), finding("CAT-001", "warning", 2), finding("CAT-017", "hint", 3)]
    io = IO::Memory.new
    Catalyst::Formatter.for("json").output(results, io, "warning")
    io.to_s.should contain("CAT-013")
    io.to_s.should contain("CAT-001")
    io.to_s.should_not contain("CAT-017")
  end

  it "renders a hint finding without raising (no invalid color)" do
    io = IO::Memory.new
    Catalyst::Formatter.for("terminal").output([finding("CAT-017", "hint", 1)], io, "hint")
    io.to_s.should contain("CAT-017")
  end

  it "reports non-error severities as warnings in SARIF" do
    io = IO::Memory.new
    Catalyst::Formatter.for("sarif").output([finding("CAT-017", "info", 1)], io, "hint")
    io.to_s.should contain(%q("level":"warning"))
    io.to_s.should_not contain(%q("level":"error"))
  end
end

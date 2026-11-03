require "../spec_helper"

private def finding(rule_id : String, severity : String, line : Int32) : Catalyst::Result
  Catalyst::Result.new(rule_id: rule_id, severity: severity, message: "message", file: "sample.cr", line: line, column: 1)
end

# Severity filtering used to be reimplemented per formatter, with the
# comparison inverted: a `min_severity` of warning dropped `error` findings
# and kept only info/hint. It now lives in one place, and formatters render
# whatever they are handed.
private def filtered(results : Array(Catalyst::Result), min_severity : String) : Array(Catalyst::Result)
  Catalyst::Formatter.filter_by_severity(results, min_severity)
end

describe Catalyst::Formatters do
  describe ".filter_by_severity" do
    it "keeps only findings at the minimum severity" do
      results = [finding("CAT-013", "error", 1), finding("CAT-017", "hint", 2)]
      kept = filtered(results, "error")
      kept.map(&.rule_id).should eq(["CAT-013"])
    end

    it "keeps error findings above the minimum" do
      results = [finding("CAT-013", "error", 1), finding("CAT-001", "warning", 2), finding("CAT-017", "hint", 3)]
      kept = filtered(results, "warning")
      kept.map(&.rule_id).should eq(["CAT-013", "CAT-001"])
    end

    # An unknown level must not silently match everything.
    it "treats an unknown minimum as the least severe level" do
      results = [finding("CAT-013", "error", 1), finding("CAT-017", "hint", 2)]
      filtered(results, "bogus").size.should eq(2)
    end
  end

  describe "Terminal" do
    it "renders a hint finding without raising (no invalid color)" do
      io = IO::Memory.new
      Catalyst::Formatter.for("terminal").output(filtered([finding("CAT-017", "hint", 1)], "hint"), io)
      io.to_s.should contain("CAT-017")
    end

    it "prints nothing when the report is empty" do
      io = IO::Memory.new
      Catalyst::Formatter.for("terminal").output([] of Catalyst::Result, io)
      io.to_s.should be_empty
    end
  end

  describe "Json" do
    it "emits the findings it is given" do
      io = IO::Memory.new
      Catalyst::Formatter.for("json").output(filtered([finding("CAT-013", "error", 1)], "warning"), io)
      io.to_s.should contain("CAT-013")
    end
  end

  describe "Sarif" do
    it "reports non-error severities as warnings" do
      io = IO::Memory.new
      Catalyst::Formatter.for("sarif").output([finding("CAT-017", "info", 1)], io)
      io.to_s.should contain(%q("level":"warning"))
      io.to_s.should_not contain(%q("level":"error"))
    end
  end
end

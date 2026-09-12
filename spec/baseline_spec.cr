require "./spec_helper"

private def sample_result(rule_id : String = "CAT-001") : Catalyst::Result
  Catalyst::Result.new(
    rule_id: rule_id,
    severity: "warning",
    message: "Use `min`/`max`",
    file: "sample.cr",
    line: 3,
    column: 1,
  )
end

describe Catalyst::Baseline do
  it "builds keys without line numbers" do
    Catalyst::Baseline.key(sample_result).should eq("sample.cr:CAT-001:Use `min`/`max`")
  end

  it "round-trips through a file" do
    path = File.join(Dir.tempdir, "catalyst_baseline_#{Random.rand(1_000_000_000)}.json")
    begin
      Catalyst::Baseline.write(path, [sample_result, sample_result("CAT-004")]).should eq(2)
      known = Catalyst::Baseline.load(path)
      known.size.should eq(2)
      Catalyst::Baseline.new_findings([sample_result], known).should be_empty
      fresh = sample_result("CAT-009")
      Catalyst::Baseline.new_findings([fresh], known).should eq([fresh])
    ensure
      File.delete(path) if File.exists?(path)
    end
  end

  it "treats a missing baseline as everything-new" do
    known = Catalyst::Baseline.load("/nonexistent/baseline.json")
    Catalyst::Baseline.new_findings([sample_result], known).should eq([sample_result])
  end
end

describe "inline suppressions" do
  it "honors trailing catalyst:disable comments" do
    code = "[3, 1, 2].sort.first # catalyst:disable CAT-001\n"
    dir = File.join(Dir.tempdir, "catalyst_spec_#{Random.rand(1_000_000_000)}")
    Dir.mkdir_p(dir)
    path = File.join(dir, "sample.cr")
    begin
      File.write(path, code)
      results = Catalyst::Runner.new(Catalyst::Config.default, Catalyst::Options.new).run([path])
      results.select { |result| result.rule_id == "CAT-001" }.should be_empty
    ensure
      File.delete(path) if File.exists?(path)
      Dir.delete(dir) if Dir.exists?(dir)
    end
  end

  it "honors disable comments on the line above" do
    code = "# catalyst:disable CAT-001\n[3, 1, 2].sort.first\n"
    dir = File.join(Dir.tempdir, "catalyst_spec_#{Random.rand(1_000_000_000)}")
    Dir.mkdir_p(dir)
    path = File.join(dir, "sample.cr")
    begin
      File.write(path, code)
      results = Catalyst::Runner.new(Catalyst::Config.default, Catalyst::Options.new).run([path])
      results.select { |result| result.rule_id == "CAT-001" }.should be_empty
    ensure
      File.delete(path) if File.exists?(path)
      Dir.delete(dir) if Dir.exists?(dir)
    end
  end

  it "keeps findings for other rules when scoped" do
    code = "[3, 1, 2].sort.first # catalyst:disable CAT-004\n"
    dir = File.join(Dir.tempdir, "catalyst_spec_#{Random.rand(1_000_000_000)}")
    Dir.mkdir_p(dir)
    path = File.join(dir, "sample.cr")
    begin
      File.write(path, code)
      results = Catalyst::Runner.new(Catalyst::Config.default, Catalyst::Options.new).run([path])
      results.map(&.rule_id).should contain("CAT-001")
    ensure
      File.delete(path) if File.exists?(path)
      Dir.delete(dir) if Dir.exists?(dir)
    end
  end
end

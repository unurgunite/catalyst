require "../../spec_helper"

# The mixin exists so loop context is a depth count, not a boolean: a flag
# breaks on nested loops and on a sibling block that follows a loop.
describe Catalyst::Rules::LoopTracking do
  it "counts while/until bodies as loops" do
    rule = Catalyst::Rules::ShiftUnshiftToDeque.new
    run_rule(rule, "while list.size > 0\n  list.shift\nend").size.should eq(1)
    run_rule(rule, "until done\n  list.shift\nend").size.should eq(1)
  end

  it "treats listed block methods as loops" do
    rule = Catalyst::Rules::ShiftUnshiftToDeque.new
    run_rule(rule, "list.each { |x| list.shift }").size.should eq(1)
    run_rule(rule, "3.times { list.shift }").size.should eq(1)
  end

  it "does not treat an unrelated block as a loop" do
    rule = Catalyst::Rules::ShiftUnshiftToDeque.new
    run_rule(rule, "list.tap { list.shift }").size.should eq(0)
  end

  it "stays silent outside any loop" do
    rule = Catalyst::Rules::ShiftUnshiftToDeque.new
    run_rule(rule, "list.shift").size.should eq(0)
  end

  it "keeps counting inside nested loops" do
    rule = Catalyst::Rules::ShiftUnshiftToDeque.new
    run_rule(rule, "list.each { |x| other.each { list.shift } }").size.should eq(1)
  end

  it "does not leak loop context into a sibling block after a loop" do
    rule = Catalyst::Rules::ShiftUnshiftToDeque.new
    code = "list.each { |x| x }\nlist.tap { list.shift }\n"
    run_rule(rule, code).size.should eq(0)
  end

  it "resets depth between files" do
    rule = Catalyst::Rules::StringPlusToStringBuild.new
    run_rule(rule, "items.each { |i| @s += \"x\" }").size.should eq(1)
    run_rule(rule, "@s += \"x\"").size.should eq(0)
  end

  it "tracks loops for a rule that used a per-block flag (CAT-010)" do
    rule = Catalyst::Rules::StringPlusToStringBuild.new
    # `tap` runs its block once, so a concatenation inside it is not a loop.
    run_rule(rule, "items.tap { |i| result = prefix + \"suffix\" }").size.should eq(0)
    run_rule(rule, "items.each { |i| result = prefix + \"suffix\" }").size.should eq(1)
  end
end

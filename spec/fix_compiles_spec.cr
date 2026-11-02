require "./spec_helper"
require "../scripts/check_fix_compiles"

# The snippet per rule lives in scripts/check_fix_compiles.cr, which applies
# `catalyst --fix` to it and compiles the result. That script only runs in CI,
# so these examples keep it honest on every `crystal spec`: a fixable rule
# with no snippet, or a snippet left behind for a rule that lost its fix,
# fails here.
describe "fix compile cases" do
  it "has a snippet for every rule that advertises a fix" do
    fixable = Catalyst::Rule.all.select(&.auto_fixable?).map(&.id).sort!
    fixable.each do |id|
      Catalyst::FIX_COMPILE_CASES.has_key?(id).should be_true,
        "#{id} claims auto_fixable? but has no entry in FIX_COMPILE_CASES"
    end
  end

  it "only lists rules that still exist and are fixable" do
    Catalyst::FIX_COMPILE_CASES.each_key do |id|
      rule = Catalyst::Rule.all.find { |item| item.id == id }
      rule.should_not be_nil, "#{id} is not loaded anymore"
      rule.try(&.auto_fixable?).should be_true, "#{id} no longer advertises a fix"
    end
  end
end

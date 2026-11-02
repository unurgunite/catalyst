require "./spec_helper"

# Covers the rewrite helpers every auto-fixable rule shares: fixes must land
# only in code, never inside string literals or comments.
describe "auto-fix rewriting" do
  it "does not rewrite occurrences inside a trailing comment" do
    # Fixes are line replacements: the newline is re-added by the runner.
    fix_for(Catalyst::Rules::SortFirstToMin.new, "x.sort.first # sort.first here\n")
      .should eq("x.min # sort.first here")
  end

  it "does not rewrite occurrences inside a string literal" do
    fix_for(Catalyst::Rules::SortFirstToMin.new, %q(puts "sort.first" + x.sort.first))
      .should eq(%q(puts "sort.first" + x.min))
  end

  it "emits no fix when the only occurrence is inside a string" do
    fix_for(Catalyst::Rules::SortFirstToMin.new, %q(puts "sort.first")).should be_nil
  end

  it "rewrites reverse.each to reverse_each" do
    fix_for(Catalyst::Rules::ReverseToReverseEach.new, "x.reverse.each { |i| i }").should eq("x.reverse_each { |i| i }")
  end

  it "rewrites keys.each to each_key" do
    fix_for(Catalyst::Rules::HashKeysEachToEachKey.new, "h.keys.each { |k| k }").should eq("h.each_key { |k| k }")
  end
end

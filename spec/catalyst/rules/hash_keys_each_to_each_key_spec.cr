require "../../spec_helper"

module Catalyst
  module Rules
    describe HashKeysEachToEachKey do
      rule = HashKeysEachToEachKey.new

      describe "#check" do
        it "detects keys.each with block" do
          assert_finding(rule, "hash = {\"a\" => 1}\nhash.keys.each { |k| k }")
        end

        it "detects keys.each without block" do
          assert_finding(rule, "hash = {\"a\" => 1}\nhash.keys.each")
        end

        it "detects keys.each with short variable name" do
          assert_finding(rule, "h = {\"a\" => 1}\nh.keys.each")
        end

        it "detects keys.each on a typed Hash constructor" do
          assert_finding(rule, "h = Hash(String, Int32).new\nh.keys.each { |k| k }")
        end

        # `.keys` inside a macro is a macro method: NamedTupleLiteral has no
        # each_key, so the rewrite turned compiling code into
        # "undefined macro method 'NamedTupleLiteral#each_key'".
        it "detects keys.each on a Hash built by to_h" do
          assert_finding(rule, "h = (1..3).to_h { |i| {i, i} }\nh.keys.each { |k| k }")
        end

        it "detects keys.each on a Hash built by group_by" do
          assert_finding(rule, "h = [1].group_by { |i| i }\nh.keys.each { |k| k }")
        end

        it "ignores .keys.each on a NamedTuple constant" do
          assert_no_finding(rule, "CONFIG = {a: 1}\nclass Foo\n  def run\n    CONFIG.keys.each { |k| k }\n  end\nend")
        end

        it "ignores .keys.each on a receiver of unknown type" do
          assert_no_finding(rule, "def f(thing)\n  thing.keys.each { |k| k }\nend")
        end

        it "ignores .keys.each on an array" do
          assert_no_finding(rule, "a = [1, 2]\na.keys.each { |k| k }")
        end

        it "ignores each_key (already optimal)" do
          assert_no_finding(rule, "hash.each_key { |k| k }")
        end

        it "ignores each without keys" do
          assert_no_finding(rule, "hash.each { |k| k }")
        end

        it "ignores .each on array" do
          assert_no_finding(rule, "ary.each")
        end

        it "flags mutating blocks as low without a fix (delete)" do
          results = run_rule(rule, "h = {\"a\" => 1}\nh.keys.each { |k| h.delete(k) }")
          results.size.should eq(1)
          results.first.confidence.should eq("low")
          results.first.message.should contain("mutates")
          results.first.fix_replacement.should be_nil
        end

        it "flags mutating blocks as low without a fix ([]=)" do
          results = run_rule(rule, "h = {\"a\" => 1}\nh.keys.each { |k| h[k] = 1 }")
          results.size.should eq(1)
          results.first.confidence.should eq("low")
          results.first.fix_replacement.should be_nil
        end

        it "flags mutating ivar blocks as low without a fix" do
          results = run_rule(rule, "class C\n  def run\n    @h = {\"a\" => 1}\n    @h.keys.each { |k| @h.clear }\n  end\nend")
          results.size.should eq(1)
          results.first.confidence.should eq("low")
          results.first.fix_replacement.should be_nil
        end

        it "keeps the fix when another hash is mutated" do
          results = run_rule(rule, "h = {\"a\" => 1}\nh.keys.each { |k| g.delete(k) }")
          results.size.should eq(1)
          results.first.confidence.should eq("high")
          results.first.fix_replacement.should_not be_nil
        end

        it "keeps the fix for read-only blocks" do
          results = run_rule(rule, "hash = {\"a\" => 1}\nhash.keys.each { |k| k }")
          results.size.should eq(1)
          results.first.fix_replacement.should_not be_nil
        end
      end

      describe "#id" do
        it "returns CAT-006" do
          rule.id.should eq("CAT-006")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("each_key")
        end
      end
    end
  end
end

require "../../spec_helper"

module Catalyst
  module Rules
    describe HashKeysEachToEachKey do
      rule = HashKeysEachToEachKey.new

      describe "#check" do
        it "detects keys.each with block" do
          assert_finding(rule, "hash.keys.each { |k| k }")
        end

        it "detects keys.each without block" do
          assert_finding(rule, "hash.keys.each")
        end

        it "detects keys.each with short variable name" do
          assert_finding(rule, "h.keys.each")
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
          results = run_rule(rule, "h.keys.each { |k| h.delete(k) }")
          results.size.should eq(1)
          results.first.confidence.should eq("low")
          results.first.message.should contain("mutates")
          results.first.fix_replacement.should be_nil
        end

        it "flags mutating blocks as low without a fix ([]=)" do
          results = run_rule(rule, "h.keys.each { |k| h[k] = 1 }")
          results.size.should eq(1)
          results.first.confidence.should eq("low")
          results.first.fix_replacement.should be_nil
        end

        it "flags mutating ivar blocks as low without a fix" do
          results = run_rule(rule, "@h.keys.each { |k| @h.clear }")
          results.size.should eq(1)
          results.first.confidence.should eq("low")
          results.first.fix_replacement.should be_nil
        end

        it "keeps the fix when another hash is mutated" do
          results = run_rule(rule, "h.keys.each { |k| g.delete(k) }")
          results.size.should eq(1)
          results.first.confidence.should eq("high")
          results.first.fix_replacement.should_not be_nil
        end

        it "keeps the fix for read-only blocks" do
          results = run_rule(rule, "hash.keys.each { |k| k }")
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

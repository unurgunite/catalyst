require "../../spec_helper"

module Catalyst
  module Rules
    describe GroupByToCounter do
      rule = GroupByToCounter.new

      describe "#check" do
        it "detects group_by.map with tuple and .size" do
          assert_finding(rule, "ary.group_by(&.foo).map { |k, v| {k, v.size} }")
        end

        it "detects group_by.map with array literal and .size" do
          assert_finding(rule, "ary.group_by(&.foo).map { |k, v| [k, v.size] }")
        end

        it "ignores group_by.map without .size on value" do
          assert_no_finding(rule, "ary.group_by(&.foo).map { |k, v| {k, v} }")
        end

        it "ignores group_by.map with .length instead of .size" do
          assert_no_finding(rule, "ary.group_by(&.foo).map { |k, v| {k, v.length} }")
        end

        it "ignores group_by alone without .map" do
          assert_no_finding(rule, "ary.group_by(&.foo)")
        end

        it "ignores map without group_by" do
          assert_no_finding(rule, "ary.map { |x| x.foo }")
        end
      end

      describe "#id" do
        it "returns CAT-009" do
          rule.id.should eq("CAT-009")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("group_by")
        end
      end
    end
  end
end

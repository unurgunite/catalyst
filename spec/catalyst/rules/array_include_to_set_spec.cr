require "../../spec_helper"

module Catalyst
  module Rules
    describe ArrayIncludeToSet do
      rule = ArrayIncludeToSet.new

      describe "#check" do
        it "detects ary.includes?(x)" do
          assert_finding(rule, "ary.includes?(x)")
        end

        it "detects array literal includes?" do
          assert_finding(rule, "[1, 2, 3].includes?(1)")
        end

        it "detects includes? with string arg" do
          assert_finding(rule, "names.includes?(\"alice\")")
        end

        it "detects includes? inside loop" do
          assert_finding(rule, "items.each { |i| list.includes?(i) }")
        end

        it "ignores methods other than includes?" do
          assert_no_finding(rule, "ary.include?(x)")
        end

        it "ignores includes? with no args" do
          assert_no_finding(rule, "ary.includes?")
        end

        it "ignores includes? with block" do
          assert_no_finding(rule, "ary.includes? { |x| x > 0 }")
        end
      end

      describe "#id" do
        it "returns CAT-004" do
          rule.id.should eq("CAT-004")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("Set")
          rule.description.should contain("Array#include?")
        end
      end
    end
  end
end

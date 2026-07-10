require "../../spec_helper"

module Catalyst
  module Rules
    describe ValuesEachToEachValue do
      rule = ValuesEachToEachValue.new

      describe "#check" do
        it "detects values.each with block" do
          assert_finding(rule, "hash.values.each { |v| v }")
        end

        it "detects values.each without block" do
          assert_finding(rule, "hash.values.each")
        end

        it "detects values.each with short variable name" do
          assert_finding(rule, "h.values.each")
        end

        it "ignores each_value (already optimal)" do
          assert_no_finding(rule, "hash.each_value { |v| v }")
        end

        it "ignores each without values" do
          assert_no_finding(rule, "hash.each { |v| v }")
        end

        it "ignores .each on array" do
          assert_no_finding(rule, "ary.each")
        end

        it "ignores .each on keys (not values)" do
          assert_no_finding(rule, "hash.keys.each")
        end
      end

      describe "#id" do
        it "returns CAT-021" do
          rule.id.should eq("CAT-021")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("each_value")
        end
      end
    end
  end
end

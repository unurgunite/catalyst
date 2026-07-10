require "../../spec_helper"

module Catalyst
  module Rules
    describe ValuesIncludesToHasValue do
      rule = ValuesIncludesToHasValue.new

      describe "#check" do
        it "detects values.includes? with string arg" do
          assert_finding(rule, "hash.values.includes?(\"val\")")
        end

        it "detects values.includes? with variable arg" do
          assert_finding(rule, "h.values.includes?(v)")
        end

        it "ignores has_value? (already optimal)" do
          assert_no_finding(rule, "hash.has_value?(\"val\")")
        end

        it "ignores includes? on array" do
          assert_no_finding(rule, "array.includes?(x)")
        end

        it "ignores values alone (no includes?)" do
          assert_no_finding(rule, "hash.values")
        end

        it "ignores keys.includes? (not values)" do
          assert_no_finding(rule, "hash.keys.includes?(\"key\")")
        end
      end

      describe "#id" do
        it "returns CAT-031" do
          rule.id.should eq("CAT-031")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("has_value?")
        end
      end
    end
  end
end

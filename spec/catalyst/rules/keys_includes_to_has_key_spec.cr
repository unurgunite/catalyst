require "../../spec_helper"

module Catalyst
  module Rules
    describe KeysIncludesToHasKey do
      rule = KeysIncludesToHasKey.new

      describe "#check" do
        it "detects keys.includes? with string arg" do
          assert_finding(rule, "hash.keys.includes?(\"key\")")
        end

        it "detects keys.includes? with variable arg" do
          assert_finding(rule, "h.keys.includes?(k)")
        end

        it "ignores has_key? (already optimal)" do
          assert_no_finding(rule, "hash.has_key?(\"key\")")
        end

        it "ignores includes? on array" do
          assert_no_finding(rule, "array.includes?(x)")
        end

        it "ignores keys alone (no includes?)" do
          assert_no_finding(rule, "hash.keys")
        end
      end

      describe "#id" do
        it "returns CAT-030" do
          rule.id.should eq("CAT-030")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("has_key?")
        end
      end
    end
  end
end

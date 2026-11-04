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

      describe "#fix_replacement" do
        it "rewrites values.includes? to has_value?" do
          fix_for(rule, "h.values.includes?(v)").should eq("h.has_value?(v)")
        end

        it "keeps the rest of the line" do
          fix_for(rule, "ok = h.values.includes?(v) && other")
            .should eq("ok = h.has_value?(v) && other")
        end

        it "does not touch a values.includes? inside a string" do
          fix_for(rule, %(log("h.values.includes?(v)"))).should be_nil
        end

        it "declines a line with two occurrences" do
          fix_for(rule, "a.values.includes?(x) && b.values.includes?(y)").should be_nil
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

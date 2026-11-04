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

      describe "#fix_replacement" do
        it "rewrites keys.includes? to has_key?" do
          fix_for(rule, "h.keys.includes?(k)").should eq("h.has_key?(k)")
        end

        it "keeps the rest of the line" do
          fix_for(rule, "ok = h.keys.includes?(k) && other")
            .should eq("ok = h.has_key?(k) && other")
        end

        it "does not touch a keys.includes? inside a string" do
          fix_for(rule, %(log("h.keys.includes?(k)"))).should be_nil
        end

        it "declines a line with two occurrences" do
          fix_for(rule, "a.keys.includes?(x) && b.keys.includes?(y)").should be_nil
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

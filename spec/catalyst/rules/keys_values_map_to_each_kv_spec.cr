require "../../spec_helper"

module Catalyst
  module Rules
    describe KeysValuesMapToEachKv do
      rule = KeysValuesMapToEachKv.new

      describe "#check" do
        it "detects keys.map with block" do
          assert_finding(rule, "hash.keys.map { |k| k.to_s }")
        end

        it "detects keys.map without block" do
          assert_finding(rule, "hash.keys.map")
        end

        it "detects values.map with block" do
          assert_finding(rule, "hash.values.map { |v| v.to_s }")
        end

        it "detects values.map without block" do
          assert_finding(rule, "hash.values.map")
        end

        it "detects keys.map with short variable" do
          assert_finding(rule, "h.keys.map")
        end

        it "ignores each_key.map (already optimal)" do
          assert_no_finding(rule, "hash.each_key.map { |k| k }")
        end

        it "ignores each_value.map (already optimal)" do
          assert_no_finding(rule, "hash.each_value.map { |v| v }")
        end

        it "ignores map without keys/values" do
          assert_no_finding(rule, "arr.map { |x| x }")
        end

        it "ignores keys.each (not map)" do
          assert_no_finding(rule, "hash.keys.each")
        end

        it "ignores values.each (not map)" do
          assert_no_finding(rule, "hash.values.each")
        end
      end

      describe "#id" do
        it "returns CAT-024" do
          rule.id.should eq("CAT-024")
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
          rule.description.should contain("each_value")
        end
      end
    end
  end
end

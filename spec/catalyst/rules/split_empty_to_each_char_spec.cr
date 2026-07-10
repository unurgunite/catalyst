require "../../spec_helper"

module Catalyst
  module Rules
    describe SplitEmptyToEachChar do
      rule = SplitEmptyToEachChar.new

      describe "#check" do
        it "detects str.split(\"\")" do
          assert_finding(rule, "str.split(\"\")")
        end

        it "detects literal.split(\"\")" do
          assert_finding(rule, "\"literal\".split(\"\")")
        end

        it "ignores split with non-empty string" do
          assert_no_finding(rule, "str.split(\",\")")
        end

        it "ignores each_char (already optimal)" do
          assert_no_finding(rule, "str.each_char")
        end
      end

      describe "#id" do
        it "returns CAT-035" do
          rule.id.should eq("CAT-035")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("each_char")
        end
      end
    end
  end
end

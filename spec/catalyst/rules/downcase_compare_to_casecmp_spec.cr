require "../../spec_helper"

module Catalyst
  module Rules
    describe DowncaseCompareToCasecmp do
      rule = DowncaseCompareToCasecmp.new

      describe "#check" do
        it "detects str.downcase == other.downcase" do
          assert_finding(rule, "str.downcase == other.downcase")
        end

        it "detects str.downcase == \"foo\"" do
          assert_finding(rule, "str.downcase == \"foo\"")
        end

        it "detects str.downcase != \"foo\"" do
          assert_finding(rule, "str.downcase != \"foo\"")
        end

        it "ignores casecmp? (already optimal)" do
          assert_no_finding(rule, "str.casecmp?(other)")
        end

        it "ignores direct == without downcase" do
          assert_no_finding(rule, "str == other")
        end

        it "ignores .downcase alone" do
          assert_no_finding(rule, "str.downcase")
        end
      end

      describe "#id" do
        it "returns CAT-018" do
          rule.id.should eq("CAT-018")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("compare")
          rule.description.should contain("downcase")
        end
      end
    end
  end
end

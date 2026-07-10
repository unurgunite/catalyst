require "../../spec_helper"

module Catalyst
  module Rules
    describe PowerToMath do
      rule = PowerToMath.new

      describe "#check" do
        it "detects x ** 2" do
          assert_finding(rule, "x ** 2")
        end

        it "detects x ** 0.5" do
          assert_finding(rule, "x ** 0.5")
        end

        it "ignores x ** 3" do
          assert_no_finding(rule, "x ** 3")
        end

        it "ignores x * x" do
          assert_no_finding(rule, "x * x")
        end

        it "ignores x ** 2.5" do
          assert_no_finding(rule, "x ** 2.5")
        end
      end

      describe "#id" do
        it "returns CAT-044" do
          rule.id.should eq("CAT-044")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("Math.sqrt")
        end
      end
    end
  end
end

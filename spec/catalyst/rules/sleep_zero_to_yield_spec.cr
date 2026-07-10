require "../../spec_helper"

module Catalyst
  module Rules
    describe SleepZeroToYield do
      rule = SleepZeroToYield.new

      describe "#check" do
        it "detects sleep(0)" do
          assert_finding(rule, "sleep(0)")
        end

        it "detects sleep 0" do
          assert_finding(rule, "sleep 0")
        end

        it "ignores sleep(1)" do
          assert_no_finding(rule, "sleep(1)")
        end

        it "ignores sleep(0.5)" do
          assert_no_finding(rule, "sleep(0.5)")
        end

        it "ignores Fiber.yield" do
          assert_no_finding(rule, "Fiber.yield")
        end
      end

      describe "#id" do
        it "returns CAT-042" do
          rule.id.should eq("CAT-042")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("Fiber.yield")
        end
      end
    end
  end
end

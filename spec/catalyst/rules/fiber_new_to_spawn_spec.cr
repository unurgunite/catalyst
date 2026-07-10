require "../../spec_helper"

module Catalyst
  module Rules
    describe FiberNewToSpawn do
      rule = FiberNewToSpawn.new

      describe "#check" do
        it "detects Fiber.new { do_work }.resume" do
          assert_finding(rule, "Fiber.new { do_work }.resume")
        end

        it "ignores Fiber.new { do_work } without .resume" do
          assert_no_finding(rule, "Fiber.new { do_work }")
        end

        it "ignores spawn { do_work }" do
          assert_no_finding(rule, "spawn { do_work }")
        end

        it "ignores fiber.resume on existing fiber" do
          assert_no_finding(rule, "fiber.resume")
        end
      end

      describe "#id" do
        it "returns CAT-050" do
          rule.id.should eq("CAT-050")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("spawn")
        end
      end
    end
  end
end

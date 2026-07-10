require "../../spec_helper"

module Catalyst
  module Rules
    describe ThreadNewToSpawn do
      rule = ThreadNewToSpawn.new

      describe "#check" do
        it "detects Thread.new { do_work }" do
          assert_finding(rule, "Thread.new { do_work }")
        end

        it "detects Thread.new without block" do
          assert_finding(rule, "Thread.new")
        end

        it "ignores spawn { do_work }" do
          assert_no_finding(rule, "spawn { do_work }")
        end

        it "ignores Thread.list" do
          assert_no_finding(rule, "Thread.list")
        end
      end

      describe "#id" do
        it "returns CAT-049" do
          rule.id.should eq("CAT-049")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
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

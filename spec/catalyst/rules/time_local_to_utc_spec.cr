require "../../spec_helper"

module Catalyst
  module Rules
    describe TimeLocalToUtc do
      rule = TimeLocalToUtc.new

      describe "#check" do
        it "detects Time.local with args" do
          assert_finding(rule, "Time.local(2024, 1, 1)")
        end

        it "detects Time.local with more args" do
          assert_finding(rule, "Time.local(2024, 1, 1, 12, 30)")
        end

        it "ignores Time.utc" do
          assert_no_finding(rule, "Time.utc(2024, 1, 1)")
        end

        it "ignores Time.now" do
          assert_no_finding(rule, "Time.now")
        end

        it "detects Time.local in variable assignment" do
          assert_finding(rule, "local_time = Time.local(2024, 1, 1)")
        end
      end

      describe "#id" do
        it "returns CAT-017" do
          rule.id.should eq("CAT-017")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("Time.utc")
          rule.description.should contain("Time.local")
        end
      end
    end
  end
end

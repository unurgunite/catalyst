require "../../spec_helper"

module Catalyst
  module Rules
    describe ParseToConstant do
      rule = ParseToConstant.new

      describe "#check" do
        it "detects URI.parse" do
          assert_finding(rule, "URI.parse(\"https://example.com\")")
        end

        it "detects Time.parse" do
          assert_finding(rule, "Time.parse(\"2024-01-01\", \"%Y-%m-%d\", Time::Location::UTC)")
        end

        it "detects Time.parse!" do
          assert_finding(rule, "Time.parse!(\"2024-01-01\", \"%Y-%m-%d\", Time::Location::UTC)")
        end

        it "ignores URI.parse?" do
          assert_no_finding(rule, "URI.parse?(\"https://example.com\")")
        end

        it "ignores JSON.parse" do
          assert_no_finding(rule, "JSON.parse(\"{\\\"key\\\": 1}\")")
        end

        it "ignores non-parse calls" do
          assert_no_finding(rule, "URI.new(\"https://example.com\")")
        end
      end

      describe "#id" do
        it "returns CAT-041" do
          rule.id.should eq("CAT-041")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("URI.parse")
        end
      end
    end
  end
end

require "../../spec_helper"

module Catalyst
  module Rules
    describe ParseToConstant do
      rule = ParseToConstant.new

      describe "#check" do
        it "detects URI.parse in a loop" do
          assert_finding(rule, "names.each { |n| URI.parse(\"https://example.com\") }")
        end

        it "detects Time.parse in a loop" do
          assert_finding(rule, "names.each { |n| Time.parse(\"2024-01-01\", \"%Y-%m-%d\", Time::Location::UTC) }")
        end

        it "detects Time.parse! in a loop" do
          assert_finding(rule, "names.each { |n| Time.parse!(\"2024-01-01\", \"%Y-%m-%d\", Time::Location::UTC) }")
        end

        it "ignores URI.parse?" do
          assert_no_finding(rule, "names.each { |n| URI.parse?(\"https://example.com\") }")
        end

        it "ignores JSON.parse" do
          assert_no_finding(rule, "names.each { |n| JSON.parse(\"{\\\"key\\\": 1}\") }")
        end

        it "ignores non-parse calls" do
          assert_no_finding(rule, "names.each { |n| URI.new(\"https://example.com\") }")
        end

        # There is nothing to hoist when the call already runs once. This
        # rule reported every literal `URI.parse` at top level as "hoist out
        # of loop", which on real code meant sample scripts and specs.
        it "ignores a call outside any loop" do
          assert_no_finding(rule, "URI.parse(\"https://example.com\")")
        end

        it "ignores variable argument outside loops" do
          assert_no_finding(rule, "uri = URI.parse(url)")
        end

        it "flags variable argument inside loops as low confidence" do
          results = run_rule(rule, "urls.each { |url| URI.parse(url) }")
          results.size.should eq(1)
          results.first.confidence.should eq("low")
          results.first.message.should contain("if the same value")
        end

        it "flags literal argument with high confidence" do
          results = run_rule(rule, "names.each { |n| URI.parse(\"https://example.com\") }")
          results.size.should eq(1)
          results.first.confidence.should eq("high")
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

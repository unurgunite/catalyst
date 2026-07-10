require "../../spec_helper"

module Catalyst
  module Rules
    describe StringBuildFusion do
      rule = StringBuildFusion.new

      describe "#check" do
        it "detects string literal + string literal" do
          assert_finding(rule, "\"hello \" + \"world\"")
        end

        it "detects string literal + variable" do
          assert_finding(rule, "\"hello\" + name")
        end

        it "ignores string literal method calls other than +" do
          assert_no_finding(rule, "\"hello\".size")
        end

        it "ignores numeric addition" do
          assert_no_finding(rule, "42 + 1")
        end

        it "ignores variable + string" do
          assert_no_finding(rule, "name + \"hello\"")
        end
      end

      describe "#id" do
        it "returns CAT-040" do
          rule.id.should eq("CAT-040")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("String.build")
        end
      end
    end
  end
end

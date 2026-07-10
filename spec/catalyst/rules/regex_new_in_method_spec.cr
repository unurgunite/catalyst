require "../../spec_helper"

module Catalyst
  module Rules
    describe RegexNewInMethod do
      rule = RegexNewInMethod.new

      describe "#check" do
        it "detects Regex.new" do
          assert_finding(rule, "Regex.new(/pattern/)")
        end

        it "detects Regex.compile" do
          assert_finding(rule, "Regex.compile(\"pattern\")")
        end

        it "detects Regex.new in method" do
          assert_finding(rule, "def foo\n  Regex.new(/x/)\nend")
        end

        it "ignores Regex.new assigned to constant" do
          assert_no_finding(rule, "RE = Regex.new(/pattern/)")
        end

        it "ignores non-Regex calls" do
          assert_no_finding(rule, "Foo.new(\"bar\")")
        end
      end

      describe "#id" do
        it "returns CAT-039" do
          rule.id.should eq("CAT-039")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("Regex.new")
        end
      end
    end
  end
end

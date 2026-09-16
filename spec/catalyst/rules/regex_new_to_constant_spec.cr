require "../../spec_helper"

module Catalyst
  module Rules
    describe RegexNewToConstant do
      rule = RegexNewToConstant.new

      describe "#check" do
        it "detects Regex.new" do
          assert_finding(rule, "Regex.new(\"pattern\")")
        end

        it "detects Regex.compile" do
          assert_finding(rule, "Regex.compile(\"pattern\")")
        end

        it "detects Regex.new in block" do
          assert_finding(rule, "[1, 2, 3].each { Regex.new(\"pattern\") }")
        end

        it "emits a fix for literal patterns" do
          results = run_rule(rule, %q(rx = Regex.new("user-id")))
          results.size.should eq(1)
          results.first.fix_replacement.should eq(%q(rx = USER_ID))
        end

        it "emits no fix for dynamic patterns" do
          results = run_rule(rule, "rx = Regex.new(pattern)")
          results.size.should eq(1)
          results.first.fix_replacement.should be_nil
        end

        it "ignores Regex.new assigned to constant" do
          assert_no_finding(rule, "RE = Regex.new(\"pattern\")")
        end

        it "ignores non-Regex calls" do
          assert_no_finding(rule, "Foo.new(\"bar\")")
        end
      end

      describe "#id" do
        it "returns CAT-019" do
          rule.id.should eq("CAT-019")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
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

require "../../spec_helper"

module Catalyst
  module Rules
    describe ReverseReverseNoop do
      rule = ReverseReverseNoop.new

      describe "#check" do
        it "detects arr.reverse.reverse" do
          assert_finding(rule, "arr.reverse.reverse")
        end

        it "ignores arr.reverse.sort" do
          assert_no_finding(rule, "arr.reverse.sort")
        end

        it "detects arr.reverse.reverse.reverse" do
          assert_finding(rule, "arr.reverse.reverse.reverse", 2)
        end

        it "ignores single reverse" do
          assert_no_finding(rule, "arr.reverse")
        end

        it "ignores non-reverse chains" do
          assert_no_finding(rule, "arr.sort.sort")
        end
      end

      describe "#id" do
        it "returns CAT-046" do
          rule.id.should eq("CAT-046")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("reverse.reverse")
        end
      end
    end
  end
end

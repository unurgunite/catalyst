require "../../spec_helper"

module Catalyst
  module Rules
    describe UpcaseDowncaseNoop do
      rule = UpcaseDowncaseNoop.new

      describe "#check" do
        it "detects str.upcase.downcase" do
          assert_finding(rule, "str.upcase.downcase")
        end

        it "detects str.downcase.upcase" do
          assert_finding(rule, "str.downcase.upcase")
        end

        it "ignores str.upcase.strip" do
          assert_no_finding(rule, "str.upcase.strip")
        end

        it "ignores single upcase" do
          assert_no_finding(rule, "str.upcase")
        end

        it "ignores single downcase" do
          assert_no_finding(rule, "str.downcase")
        end
      end

      describe "#id" do
        it "returns CAT-047" do
          rule.id.should eq("CAT-047")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("upcase.downcase")
        end
      end
    end
  end
end

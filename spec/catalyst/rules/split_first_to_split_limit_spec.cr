require "../../spec_helper"

module Catalyst
  module Rules
    describe SplitFirstToSplitLimit do
      rule = SplitFirstToSplitLimit.new

      describe "#check" do
        it "detects str.split(x)[0]" do
          assert_finding(rule, "str.split(\",\")[0]")
        end

        it "detects split with different delimiter" do
          assert_finding(rule, "str.split(\":\")[0]")
        end

        it "ignores split with limit (already optimal)" do
          assert_no_finding(rule, "str.split(\",\", 2)[0]")
        end

        it "ignores split with index other than 0" do
          assert_no_finding(rule, "str.split(\",\")[1]")
        end

        it "ignores split without index" do
          assert_no_finding(rule, "str.split(\",\")")
        end
      end

      describe "#id" do
        it "returns CAT-032" do
          rule.id.should eq("CAT-032")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("split")
        end
      end
    end
  end
end

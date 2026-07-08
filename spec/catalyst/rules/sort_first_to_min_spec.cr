require "../../spec_helper"

module Catalyst
  module Rules
    describe SortFirstToMin do
      rule = SortFirstToMin.new

      describe "#check" do
        it "detects sort.first" do
          assert_finding(rule, "[1, 2, 3].sort.first")
        end

        it "detects sort.last" do
          assert_finding(rule, "[1, 2, 3].sort.last")
        end

        it "detects sort.first on method chain" do
          assert_finding(rule, "ary.map(&.id).sort.first")
        end

        it "ignores .first without sort" do
          assert_no_finding(rule, "[1, 2, 3].first")
        end

        it "ignores .last without sort" do
          assert_no_finding(rule, "[1, 2, 3].last")
        end

        it "ignores .min (already optimal)" do
          assert_no_finding(rule, "[1, 2, 3].min")
        end

        it "ignores .max (already optimal)" do
          assert_no_finding(rule, "[1, 2, 3].max")
        end

        it "ignores sort with block" do
          assert_no_finding(rule, "[1, 2, 3].sort { |a, b| b <=> a }.first")
        end

        it "ignores sort.first with argument" do
          assert_no_finding(rule, "%w(c b a).sort.first(2)")
        end

        it "ignores sort.last with argument" do
          assert_no_finding(rule, "%w(c b a).sort.last(2)")
        end
      end

      describe "#id" do
        it "returns CAT-001" do
          rule.id.should eq("CAT-001")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("min")
          rule.description.should contain("max")
        end
      end
    end
  end
end

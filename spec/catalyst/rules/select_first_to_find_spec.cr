require "../../spec_helper"

module Catalyst
  module Rules
    describe SelectFirstToFind do
      rule = SelectFirstToFind.new

      describe "#check" do
        it "detects select{}.first" do
          assert_finding(rule, "[1, 2, 3].select { |x| x.even? }.first")
        end

        it "detects select(&.even?).first" do
          assert_finding(rule, "[1, 2, 3].select(&.even?).first")
        end

        it "detects select{}.first?" do
          assert_finding(rule, "[1, 2, 3].select { |x| x.even? }.first?")
        end

        it "detects filter{}.first" do
          assert_finding(rule, "[1, 2, 3].filter { |x| x.even? }.first")
        end

        it "detects chained select.first" do
          assert_finding(rule, "ary.select(&.foo).first")
        end

        it "ignores select{}.last" do
          assert_no_finding(rule, "[1, 2, 3].select { |x| x.even? }.last")
        end

        it "ignores first without select" do
          assert_no_finding(rule, "[1, 2, 3].first")
        end

        it "ignores find (already optimal)" do
          assert_no_finding(rule, "[1, 2, 3].find { |x| x.even? }")
        end

        it "ignores select alone" do
          assert_no_finding(rule, "[1, 2, 3].select { |x| x.even? }")
        end

        it "ignores select.first with argument" do
          assert_no_finding(rule, "[1, 2, 3].select { |x| x.even? }.first(2)")
        end
      end

      describe "#id" do
        it "returns CAT-008" do
          rule.id.should eq("CAT-008")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("find")
          rule.description.should contain("select")
        end
      end
    end
  end
end

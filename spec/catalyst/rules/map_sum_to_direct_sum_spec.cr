require "../../spec_helper"

module Catalyst
  module Rules
    describe MapSumToDirectSum do
      rule = MapSumToDirectSum.new

      describe "#check" do
        it "detects map{}.sum" do
          assert_finding(rule, "[1, 2, 3].map { |x| x * 2 }.sum")
        end

        it "detects map(&.to_i).sum" do
          assert_finding(rule, "(1..3).map(&.to_i).sum")
        end

        it "detects map{}.sum(initial)" do
          assert_finding(rule, "[1, 2, 3].map { |x| x * 2 }.sum(10)")
        end

        it "detects chained map.sum" do
          assert_finding(rule, "ary.map(&.id).sum")
        end

        it "ignores sum without map" do
          assert_no_finding(rule, "[1, 2, 3].sum")
        end

        it "ignores sum with block without map" do
          assert_no_finding(rule, "[1, 2, 3].sum { |x| x * 2 }")
        end

        it "ignores map alone" do
          assert_no_finding(rule, "[1, 2, 3].map { |x| x * 2 }")
        end

        it "ignores select{}.sum (different method)" do
          assert_no_finding(rule, "[1, 2, 3].select { |x| x.even? }.sum")
        end
      end

      describe "#id" do
        it "returns CAT-002" do
          rule.id.should eq("CAT-002")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("map")
          rule.description.should contain("sum")
        end
      end
    end
  end
end

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

      describe "#fix_replacement" do
        it "folds map into sum" do
          fix_for(rule, "x = [1, 2].map { |n| n * 2 }.sum").should eq(
            "x = [1, 2].sum { |n| n * 2 }"
          )
        end

        # Folding left the initial value after the block: `sum { ... }(0)`,
        # which does not parse. Moving it inside needs the block text, so the
        # rule reports the finding without a fix.
        it "emits no fix when sum takes an initial value" do
          fix_for(rule, "x = [1, 2].map { |n| n * 2 }.sum(0)").should be_nil
        end

        # A greedy body swallowed an enclosing block's closing brace.
        it "stops at the inner block's closing brace" do
          fix_for(rule, "b { arr.map { |x| x * 2 }.sum }").should eq(
            "b { arr.sum { |x| x * 2 } }"
          )
        end
      end
    end
  end
end

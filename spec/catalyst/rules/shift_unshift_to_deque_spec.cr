require "../../spec_helper"

module Catalyst
  module Rules
    describe ShiftUnshiftToDeque do
      rule = ShiftUnshiftToDeque.new

      describe "#check" do
        it "detects .shift inside loop" do
          assert_finding(rule, "items.each { |i| queue.shift }")
        end

        it "detects .unshift inside loop" do
          assert_finding(rule, "while active\n  queue.unshift(item)\nend")
        end

        it "ignores top-level .shift (e.g. CLI args)" do
          assert_no_finding(rule, "args.shift")
        end

        it "ignores .unshift outside loops" do
          assert_no_finding(rule, "[1, 2, 3].unshift(0)")
        end

        it "ignores .shift on variable outside loops" do
          assert_no_finding(rule, "ary = [1, 2, 3]\nary.shift")
        end

        it "ignores .push (not shift/unshift)" do
          assert_no_finding(rule, "[1, 2, 3].push(4)")
        end

        it "ignores .pop (not shift/unshift)" do
          assert_no_finding(rule, "[1, 2, 3].pop")
        end

        it "ignores .size (not shift/unshift)" do
          assert_no_finding(rule, "[1, 2, 3].size")
        end
      end

      describe "#id" do
        it "returns CAT-005" do
          rule.id.should eq("CAT-005")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("Deque")
        end
      end
    end
  end
end

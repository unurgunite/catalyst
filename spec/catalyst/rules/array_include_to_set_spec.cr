require "../../spec_helper"

module Catalyst
  module Rules
    describe ArrayIncludeToSet do
      rule = ArrayIncludeToSet.new

      describe "#check" do
        it "ignores bare variable receiver (unknown type)" do
          assert_no_finding(rule, "ary.includes?(x)")
        end

        it "ignores method param receiver" do
          assert_no_finding(rule, "def f(ary)\n  ary.includes?(x)\nend")
        end

        it "ignores call result receiver" do
          assert_no_finding(rule, "load_set(f).includes?(x)")
        end

        it "ignores variable assigned from Set literal" do
          assert_no_finding(rule, "s = Set{1, 2, 3}\ns.includes?(x)")
        end

        it "ignores variable reassigned from array to Set" do
          assert_no_finding(rule, "a = [1, 2]\na = Set{3}\na.includes?(3)")
        end

        it "detects variable assigned from array literal" do
          assert_finding(rule, "list = [1, 2, 3, 4, 5, 6, 7, 8, 9]\nlist.includes?(x)")
        end

        it "ignores small array variable outside loops" do
          assert_no_finding(rule, "list = [1, 2, 3]\nlist.includes?(x)")
        end

        it "detects small array variable inside loops" do
          assert_finding(rule, "list = [1, 2, 3]\nitems.each { |i| list.includes?(i) }")
        end

        it "detects array variable inside while loop" do
          assert_finding(rule, "list = [1, 2, 3, 4, 5, 6, 7, 8, 9]\nwhile running\n  list.includes?(item)\nend")
        end

        it "ignores small array literal outside loops" do
          assert_no_finding(rule, "[1, 2, 3].includes?(1)")
        end

        it "detects small array literal inside loops" do
          assert_finding(rule, "items.each { |i| [1, 2, 3].includes?(i) }")
        end

        it "ignores Range#include? (already O(1))" do
          assert_no_finding(rule, "(1..512).includes?(threads)")
          assert_no_finding(rule, "1..512.includes?(threads)")
        end

        it "ignores small word literal outside loops" do
          assert_no_finding(rule, "%w[none warning info debug].includes?(level)")
        end

        it "detects includes? with string arg on array variable" do
          assert_finding(rule, "names = [\"a\", \"b\", \"c\", \"d\", \"e\", \"f\", \"g\", \"h\", \"i\"]\nnames.includes?(\"alice\")")
        end

        it "detects array variable inside loop" do
          assert_finding(rule, "list = [1, 2, 3, 4, 5, 6, 7, 8, 9]\nitems.each { |i| list.includes?(i) }")
        end

        it "ignores methods other than includes?" do
          assert_no_finding(rule, "ary = [1, 2]\nary.include?(x)")
        end

        it "ignores includes? with no args" do
          assert_no_finding(rule, "ary = [1, 2]\nary.includes?")
        end

        it "ignores includes? with block" do
          assert_no_finding(rule, "ary = [1, 2]\nary.includes? { |x| x > 0 }")
        end
      end

      describe "#id" do
        it "returns CAT-004" do
          rule.id.should eq("CAT-004")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("Set")
          rule.description.should contain("Array#include?")
        end
      end
    end
  end
end

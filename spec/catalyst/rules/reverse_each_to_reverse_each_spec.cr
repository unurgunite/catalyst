require "../../spec_helper"

module Catalyst
  module Rules
    describe ReverseEachToReverseEach do
      rule = ReverseEachToReverseEach.new

      describe "#check" do
        it "detects reverse.each with block" do
          assert_finding(rule, "ary.reverse.each { |x| x }")
        end

        it "detects reverse.each without block" do
          assert_finding(rule, "ary.reverse.each")
        end

        it "detects reverse.each on literal" do
          assert_finding(rule, "[1, 2, 3].reverse.each")
        end

        it "ignores reverse_each (already optimal)" do
          assert_no_finding(rule, "ary.reverse_each { |x| x }")
        end

        it "ignores plain each" do
          assert_no_finding(rule, "ary.each { |x| x }")
        end

        it "ignores plain reverse" do
          assert_no_finding(rule, "ary.reverse")
        end
      end

      describe "#id" do
        it "returns CAT-007" do
          rule.id.should eq("CAT-007")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("reverse_each")
        end
      end
    end
  end
end

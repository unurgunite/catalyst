require "../../spec_helper"

module Catalyst
  module Rules
    describe SelectMapToCompactMap do
      rule = SelectMapToCompactMap.new

      describe "#check" do
        it "detects select{}.map{}" do
          assert_finding(rule, "[1, 2, 3].select { |x| x > 0 }.map { |x| x * 2 }")
        end

        it "detects select.map (no select block)" do
          assert_finding(rule, "[1, 2, 3].select.map { |x| x * 2 }")
        end

        it "detects select(&.positive?).map(&.to_s)" do
          assert_finding(rule, "[1, 2, 3].select(&.positive?).map(&.to_s)")
        end

        it "ignores map without select" do
          assert_no_finding(rule, "[1, 2, 3].map { |x| x * 2 }")
        end

        it "ignores select without map" do
          assert_no_finding(rule, "[1, 2, 3].select { |x| x > 0 }")
        end

        it "ignores compact_map (already optimal)" do
          assert_no_finding(rule, "[1, 2, 3].compact_map { |x| x * 2 if x > 0 }")
        end

        it "ignores reject.map (different inner method)" do
          assert_no_finding(rule, "[1, 2, 3].reject { |x| x > 0 }.map { |x| x * 2 }")
        end
      end

      describe "#id" do
        it "returns CAT-033" do
          rule.id.should eq("CAT-033")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("compact_map")
          rule.description.should contain("select")
          rule.description.should contain("map")
        end
      end
    end
  end
end

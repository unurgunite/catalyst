require "../../spec_helper"

module Catalyst
  module Rules
    describe EachWithIndexMapToMapWithIndex do
      rule = EachWithIndexMapToMapWithIndex.new

      describe "#check" do
        it "detects each_with_index.map{}" do
          assert_finding(rule, "[1, 2, 3].each_with_index.map { |x, i| x * i }")
        end

        it "detects each_with_index.map without block" do
          assert_finding(rule, "[1, 2, 3].each_with_index.map")
        end

        it "ignores map_with_index (already optimal)" do
          assert_no_finding(rule, "[1, 2, 3].map_with_index { |x, i| x * i }")
        end

        it "ignores each_with_index without map" do
          assert_no_finding(rule, "[1, 2, 3].each_with_index { |x, i| x * i }")
        end

        it "ignores map without each_with_index" do
          assert_no_finding(rule, "[1, 2, 3].map { |x| x }")
        end

        it "ignores each_with_object.map (different inner method)" do
          assert_no_finding(rule, "[1, 2, 3].each_with_object([] of Int32) { |x, a| a << x }.map { |x| x * 2 }")
        end
      end

      describe "#id" do
        it "returns CAT-034" do
          rule.id.should eq("CAT-034")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("map_with_index")
          rule.description.should contain("each_with_index")
          rule.description.should contain("map")
        end
      end
    end
  end
end

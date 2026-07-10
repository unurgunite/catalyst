require "../../spec_helper"

module Catalyst
  module Rules
    describe CharsEachToEachChar do
      rule = CharsEachToEachChar.new

      describe "#check" do
        it "detects str.chars.each with block" do
          assert_finding(rule, "str.chars.each { |c| puts c }")
        end

        it "detects str.chars.each without block" do
          assert_finding(rule, "str.chars.each")
        end

        it "ignores each_char (already optimal)" do
          assert_no_finding(rule, "str.each_char { |c| puts c }")
        end

        it "ignores array each (not chars call)" do
          assert_no_finding(rule, "ary.each { |x| x }")
        end

        it "ignores chars alone (no each)" do
          assert_no_finding(rule, "str.chars")
        end
      end

      describe "#id" do
        it "returns CAT-036" do
          rule.id.should eq("CAT-036")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("each_char")
        end
      end
    end
  end
end

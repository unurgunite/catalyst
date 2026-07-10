require "../../spec_helper"

module Catalyst
  module Rules
    describe MatchToMatches do
      rule = MatchToMatches.new

      describe "#check" do
        it "detects str.match(/pattern/)" do
          assert_finding(rule, %q("hello".match(/world/)))
        end

        it "detects str =~ /pattern/" do
          assert_finding(rule, %q("hello" =~ /world/))
        end

        it "detects .match with variable receiver" do
          assert_finding(rule, "str.match(/pattern/)")
        end

        it "ignores str.matches? (already optimal)" do
          assert_no_finding(rule, %q("hello".matches?(/world/)))
        end

        it "ignores str.scan(/pattern/)" do
          assert_no_finding(rule, %q("hello".scan(/world/)))
        end

        it "ignores str.sub(/pattern/)" do
          assert_no_finding(rule, %q("hello".sub(/world/)))
        end

        it "ignores str.gsub(/pattern/)" do
          assert_no_finding(rule, %q("hello".gsub(/world/, "there")))
        end
      end

      describe "#id" do
        it "returns CAT-018" do
          rule.id.should eq("CAT-018")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("matches?")
        end
      end
    end
  end
end

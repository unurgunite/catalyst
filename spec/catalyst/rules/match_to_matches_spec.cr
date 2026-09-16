require "../../spec_helper"

module Catalyst
  module Rules
    describe MatchToMatches do
      rule = MatchToMatches.new

      describe "#check" do
        it "detects match in if condition" do
          assert_finding(rule, %q(if s.match(/re/); end))
        end

        it "detects match in unless condition" do
          assert_finding(rule, %q(unless s.match(/re/); end))
        end

        it "detects match in while condition" do
          assert_finding(rule, %q(while s.match(/re/); end))
        end

        it "detects match under negation and boolean operators" do
          assert_finding(rule, %q(!s.match(/re/)))
          assert_finding(rule, %q(a && s.match(/re/)))
          assert_finding(rule, %q(a || s.match(/re/)))
        end

        it "detects match in ternary condition" do
          assert_finding(rule, %q(x = s.match(/re/) ? 1 : 2))
        end

        it "ignores bare match (MatchData may be needed)" do
          assert_no_finding(rule, %q("hello".match(/world/)))
          assert_no_finding(rule, "str.match(/pattern/)")
        end

        it "ignores assigned match (MatchData is used)" do
          assert_no_finding(rule, %q(m = s.match(/re/)))
        end

        it "ignores match as method argument" do
          assert_no_finding(rule, %q(foo(s.match(/re/))))
        end

        it "ignores str =~ /pattern/ (`=~` returns Int32 | Nil, not Bool)" do
          assert_no_finding(rule, %q("hello" =~ /world/))
          assert_no_finding(rule, %q(if s =~ /re/; end))
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

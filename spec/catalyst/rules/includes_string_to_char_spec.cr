require "../../spec_helper"

module Catalyst
  module Rules
    describe IncludesStringToChar do
      rule = IncludesStringToChar.new

      describe "#check" do
        it "detects includes? with single-char string on a string variable" do
          assert_finding(rule, "str = \"abc\"\nstr.includes?(\"x\")")
        end

        # An unknown receiver may be an Array(String), where `'x'` is the
        # wrong type. Configuration lookups used to be reported this way.
        it "ignores includes? on a receiver of unknown type" do
          assert_no_finding(rule, "def f(str)\n  str.includes?(\"x\")\nend")
        end

        it "ignores includes? on an array of strings" do
          assert_no_finding(rule, "keys = [\"x\"]\nkeys.includes?(\"x\")")
        end

        it "detects includes? with single-char on literal" do
          assert_finding(rule, "\"hello\".includes?(\"h\")")
        end

        it "ignores includes? with multi-char string" do
          assert_no_finding(rule, "str = \"abc\"\nstr.includes?(\"xyz\")")
        end

        it "ignores includes? with char literal (already optimal)" do
          assert_no_finding(rule, "str.includes?('x')")
        end

        it "ignores other methods with single-char string" do
          assert_no_finding(rule, "str.starts_with?(\"x\")")
        end

        it "ignores includes? without args" do
          assert_no_finding(rule, "str.includes?")
        end
      end

      describe "#id" do
        it "returns CAT-023" do
          rule.id.should eq("CAT-023")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("char literal")
        end
      end
    end
  end
end

require "../../spec_helper"

module Catalyst
  module Rules
    describe LargeUnionTypes do
      rule = LargeUnionTypes.new

      describe "#check" do
        it "detects 4 types in union return type" do
          assert_finding(rule, "def foo : Int32 | String | Nil | Bool; 1; end")
        end

        it "detects 5 types in union return type" do
          assert_finding(rule, "def foo : Int32 | String | Nil | Bool | Float64; 1; end")
        end

        it "detects nested union with parens" do
          assert_finding(rule, "def foo : (Int32 | String) | Nil | Bool; 1; end")
        end

        it "ignores 3 types union" do
          assert_no_finding(rule, "def foo : Int32 | String | Nil; 1; end")
        end

        it "ignores single return type" do
          assert_no_finding(rule, "def foo : String; 1; end")
        end

        it "ignores method without return type" do
          assert_no_finding(rule, "def foo; 1; end")
        end
      end

      describe "#id" do
        it "returns CAT-016" do
          rule.id.should eq("CAT-016")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("Large union")
        end
      end
    end
  end
end

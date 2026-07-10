require "../../spec_helper"

module Catalyst
  module Rules
    describe StringPlusToStringBuild do
      rule = StringPlusToStringBuild.new

      describe "#check" do
        it "detects += in each block" do
          assert_finding(rule, "items.each { |item| @str += \"x\" }")
        end

        it "detects + in each block" do
          assert_finding(rule, "items.each { |item| result = prefix + \"suffix\" }")
        end

        it "detects += in times block" do
          assert_finding(rule, "3.times { @str += \"x\" }")
        end

        it "detects + in while loop" do
          assert_finding(rule, "while @i < 10\n  @str += \"x\"\n  @i += 1\nend")
        end

        it "detects += in loop with string literal" do
          assert_finding(rule, "items.each { |item| @str += \"prefix\" }")
        end

        it "detects + with string literal receiver" do
          assert_finding(rule, "items.each { |item| \"hello\" + item }")
        end

        it "ignores += outside loop" do
          assert_no_finding(rule, "@str += \"hello\"")
        end

        it "ignores numeric += in loop" do
          assert_no_finding(rule, "items.each { |item| @total += item.value }")
        end

        it "ignores numeric + in loop" do
          assert_no_finding(rule, "items.each { |item| sum = total + 1 }")
        end

        it "ignores + outside loop" do
          assert_no_finding(rule, "full = first + \" \" + last")
        end

        it "ignores standalone string concat" do
          assert_no_finding(rule, "\"hello\" + \"world\"")
        end
      end

      describe "#id" do
        it "returns CAT-010" do
          rule.id.should eq("CAT-010")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("String.build")
          rule.description.should contain("String#+")
        end
      end
    end
  end
end

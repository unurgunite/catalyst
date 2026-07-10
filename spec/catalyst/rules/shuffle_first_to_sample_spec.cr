require "../../spec_helper"

module Catalyst
  module Rules
    describe ShuffleFirstToSample do
      rule = ShuffleFirstToSample.new

      describe "#check" do
        it "detects shuffle.first with block on first" do
          assert_finding(rule, "arr.shuffle.first { |x| x }")
        end

        it "detects shuffle.first without block" do
          assert_finding(rule, "arr.shuffle.first")
        end

        it "detects shuffle.first on literal" do
          assert_finding(rule, "[1, 2, 3].shuffle.first")
        end

        it "ignores shuffle without first" do
          assert_no_finding(rule, "arr.shuffle")
        end

        it "ignores first without shuffle" do
          assert_no_finding(rule, "arr.first")
        end

        it "ignores shuffle with args" do
          assert_no_finding(rule, "arr.shuffle(1).first")
        end

        it "ignores first with args" do
          assert_no_finding(rule, "arr.shuffle.first(3)")
        end

        it "ignores other chained calls" do
          assert_no_finding(rule, "arr.sort.first")
        end
      end

      describe "#id" do
        it "returns CAT-022" do
          rule.id.should eq("CAT-022")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("sample")
          rule.description.should contain("shuffle")
        end
      end
    end
  end
end

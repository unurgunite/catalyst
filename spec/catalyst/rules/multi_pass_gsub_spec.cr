require "../../spec_helper"

module Catalyst
  module Rules
    describe MultiPassGsub do
      rule = MultiPassGsub.new

      describe "#check" do
        it "detects two chained gsub calls" do
          assert_finding(rule, %("foo".gsub("a", "b").gsub("c", "d")))
        end

        it "detects three chained gsub calls" do
          assert_finding(rule, %("foo".gsub("a", "b").gsub("c", "d").gsub("e", "f")))
        end

        it "detects four chained gsub calls" do
          assert_finding(rule, %("foo".gsub("a", "b").gsub("c", "d").gsub("e", "f").gsub("g", "h")))
        end

        it "ignores single gsub call" do
          assert_no_finding(rule, %("foo".gsub("a", "b")))
        end

        it "ignores gsub with hash argument" do
          assert_no_finding(rule, %("foo".gsub({"a" => "b", "c" => "d"})))
        end

        it "ignores gsub with block" do
          assert_no_finding(rule, %("foo".gsub(/a/) { |m| m.upcase }))
        end

        it "ignores non-gsub method chain" do
          assert_no_finding(rule, %("foo".strip.gsub("a", "b")))
        end
      end

      describe "#id" do
        it "returns CAT-011" do
          rule.id.should eq("CAT-011")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("gsub")
        end
      end
    end
  end
end

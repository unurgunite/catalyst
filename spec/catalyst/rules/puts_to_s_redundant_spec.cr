require "../../spec_helper"

module Catalyst
  module Rules
    describe PutsToSRedundant do
      rule = PutsToSRedundant.new

      describe "#check" do
        it "detects puts obj.to_s" do
          assert_finding(rule, "puts obj.to_s")
        end

        it "detects print obj.to_s" do
          assert_finding(rule, "print obj.to_s")
        end

        it "detects STDOUT.puts obj.to_s" do
          assert_finding(rule, "STDOUT.puts obj.to_s")
        end

        it "ignores puts obj" do
          assert_no_finding(rule, "puts obj")
        end

        it "ignores obj.to_s" do
          assert_no_finding(rule, "obj.to_s")
        end

        it "ignores puts with multiple args" do
          assert_no_finding(rule, "puts obj.to_s, other")
        end
      end

      describe "#id" do
        it "returns CAT-048" do
          rule.id.should eq("CAT-048")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("to_s")
        end
      end
    end
  end
end

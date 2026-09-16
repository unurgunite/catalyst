require "../../spec_helper"

module Catalyst
  module Rules
    describe CapacityHints do
      rule = CapacityHints.new

      describe "#check" do
        it "detects Array(Int32).new without size" do
          assert_finding(rule, %q(Array(Int32).new))
        end

        it "detects Hash(String, Int32).new without size" do
          assert_finding(rule, %q(Hash(String, Int32).new))
        end

        it "ignores Array(Int32).new(10) with size" do
          assert_no_finding(rule, %q(Array(Int32).new(10)))
        end

        it "ignores Array.new without generic type" do
          assert_no_finding(rule, %q(Array.new))
        end

        it "ignores Set(Int32).new" do
          assert_no_finding(rule, %q(Set(Int32).new))
        end

        it "ignores Array(Int32).new(0) with zero size" do
          assert_no_finding(rule, %q(Array(Int32).new(0)))
        end
      end

      describe "#id" do
        it "returns CAT-038" do
          rule.id.should eq("CAT-038")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#enabled_by_default?" do
        it "is opt-in (noisy on plain empty collections)" do
          rule.enabled_by_default?.should be_false
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("capacity")
          rule.description.should contain("opt-in")
        end
      end
    end
  end
end

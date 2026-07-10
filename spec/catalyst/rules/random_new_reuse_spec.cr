require "../../spec_helper"

module Catalyst
  module Rules
    describe RandomNewReuse do
      rule = RandomNewReuse.new

      describe "#check" do
        it "detects Random.new" do
          assert_finding(rule, "Random.new")
        end

        it "ignores Random.rand" do
          assert_no_finding(rule, "Random.rand")
        end

        it "ignores rand" do
          assert_no_finding(rule, "rand")
        end

        it "detects Random.new(1234) with seed" do
          assert_finding(rule, "Random.new(1234)")
        end
      end

      describe "#id" do
        it "returns CAT-043" do
          rule.id.should eq("CAT-043")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("Random.new")
        end
      end
    end
  end
end

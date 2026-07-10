require "../../spec_helper"

module Catalyst
  module Rules
    describe LoggingBlock do
      rule = LoggingBlock.new

      describe "#check" do
        it "detects logger.debug with interpolation" do
          assert_finding(rule, "logger.debug(\"hello \#{name}\")")
        end

        it "detects Log.debug with interpolation" do
          assert_finding(rule, "Log.debug(\"hello \#{name}\")")
        end

        it "detects logger.info with interpolation" do
          assert_finding(rule, "logger.info(\"user \#{id} logged in\")")
        end

        it "ignores logger.debug without interpolation" do
          assert_no_finding(rule, "logger.debug(\"hello\")")
        end

        it "ignores logger.debug with block" do
          assert_no_finding(rule, "logger.debug { \"hello \#{name}\" }")
        end

        it "ignores non-logger calls" do
          assert_no_finding(rule, "puts(\"hello \#{name}\")")
        end
      end

      describe "#id" do
        it "returns CAT-037" do
          rule.id.should eq("CAT-037")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("block form")
        end
      end
    end
  end
end

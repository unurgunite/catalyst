require "../../spec_helper"

module Catalyst
  module Rules
    describe LoggingBlock do
      rule = LoggingBlock.new

      # The receiver decides whether the suggested block form compiles, so
      # every fixture declares one. The old version of this spec used a bare
      # `logger.info("...")` with no `logger` anywhere, which is not Crystal:
      # it encoded the rule's habit of matching any call named `info`.
      custom_log = <<-CR
        module App
          module Log
            def self.info(message : String)
              puts message
            end
          end
        end
        CR

      describe "#check" do
        it "detects Log.info with interpolation" do
          code = <<-'CR'
            name = "x"
            Log.info("hello #{name}")
            CR
          assert_finding(rule, code)
        end

        it "detects Log.for(...).info with interpolation" do
          code = <<-'CR'
            name = "x"
            Log.for("ctx").info("hello #{name}")
            CR
          assert_finding(rule, code)
        end

        it "detects a project logger that declares a block overload" do
          code = <<-'CR'
            class AppLogger
              def self.warn(message : String, &)
                puts yield
              end
            end

            name = "x"
            AppLogger.warn("hello #{name}")
            CR
          assert_finding(rule, code)
        end

        it "ignores a project logger whose methods take no block" do
          # The suggested rewrite does not compile here:
          # "'App::Log.info' is not expected to be invoked with a block".
          code = "#{custom_log}\nname = \"x\"\nApp::Log.info(\"hello #{name}\")\n"
          assert_no_finding(rule, code)
        end

        it "ignores a logger without interpolation" do
          code = <<-CR
            Log.info("hello")
            CR
          assert_no_finding(rule, code)
        end

        it "ignores the block form already in use" do
          code = <<-'CR'
            name = "x"
            Log.info { "hello #{name}" }
            CR
          assert_no_finding(rule, code)
        end

        it "ignores a non-logging call with interpolation" do
          code = <<-'CR'
            name = "x"
            puts("hello #{name}")
            CR
          assert_no_finding(rule, code)
        end

        it "ignores a bare call with no receiver and no local declaration" do
          # Nothing in the file shows that `info` takes a block.
          code = <<-'CR'
            name = "x"
            info("hello #{name}")
            CR
          assert_no_finding(rule, code)
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

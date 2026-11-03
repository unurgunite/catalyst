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
          # The stdlib logger is only reachable when the file pulls it in;
          # without that, a bare `Log` is someone else's module.
          code = <<-'CR'
            require "log"
            name = "x"
            Log.info("hello #{name}")
            CR
          assert_finding(rule, code)
        end

        it "detects Log.for(...).info with interpolation" do
          code = <<-'CR'
            require "log"
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

        it "ignores the stdlib name when the file declares its own Log" do
          # A bare `Log` on a line outside `App` resolves to the stdlib, but
          # from the name alone it is indistinguishable from `App::Log`, so
          # the rule stays silent rather than risk a rewrite that does not
          # compile. Reported by two independent reviewers.
          code = "#{custom_log}\nname = \"x\"\nLog.info(\"hello \#{name}\")\n"
          assert_no_finding(rule, code)
        end

        it "detects an explicit ::Log without a require" do
          # `::Log` names the global type, so it needs no declaration here.
          code = <<-'CR'
            name = "x"
            ::Log.info("hello #{name}")
            CR
          assert_finding(rule, code)
        end

        it "ignores a bare Log in a file that does not require the stdlib one" do
          # A project's own `Log` commonly lives in another file, so nothing
          # in this file says whether the block form compiles. Staying quiet
          # is the only answer that cannot break a build.
          code = <<-'CR'
            name = "x"
            Log.info("hello #{name}")
            CR
          assert_no_finding(rule, code)
        end

        it "ignores a block overload declared on a different type" do
          # `Mine.info` takes a block; `App.info` does not. Keying the lookup
          # by method name alone reported both.
          code = <<-'CR'
            class Mine
              def self.info(message : String, &)
                puts yield
              end
            end

            class App
              def self.info(message : String)
                puts message
              end
            end

            name = "x"
            App.info("hello #{name}")
            CR
          assert_no_finding(rule, code)
        end

        it "detects a non-Log module that declares a block overload" do
          code = <<-'CR'
            module App
              class Reporter
                def self.info(message : String, &)
                  puts yield
                end
              end
            end

            name = "x"
            App::Reporter.info("hello #{name}")
            CR
          assert_finding(rule, code)
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

require "../../spec_helper"

module Catalyst
  module Rules
    describe BlockingCallInSpawn do
      rule = BlockingCallInSpawn.new

      describe "#check" do
        it "detects Process.new lexically inside spawn" do
          assert_finding(rule, "spawn { Process.new(\"worker\", args: [\"run\"]) }")
        end

        it "detects Process.run lexically inside spawn" do
          assert_finding(rule, %q(spawn { Process.run("curl", args: ["-s"]) }))
        end

        it "detects sleep with literal seconds inside spawn" do
          assert_finding(rule, "spawn { sleep 1.8 }")
        end

        it "detects sleep with span form inside spawn" do
          assert_finding(rule, "spawn { sleep 0.25.seconds }")
        end

        it "detects HTTP::Client.get inside spawn" do
          assert_finding(rule, %q(spawn { HTTP::Client.get("http://x") }))
        end

        it "detects system() inside spawn" do
          assert_finding(rule, %q(spawn { system("pkill worker") }))
        end

        it "ignores sleep 0 inside spawn (yield idiom, CAT-042)" do
          assert_no_finding(rule, "spawn { sleep 0 }")
        end

        it "ignores sleep 0.seconds inside spawn" do
          assert_no_finding(rule, "spawn { sleep 0.seconds }")
        end

        it "ignores sleep with variable arg inside spawn (unknown)" do
          assert_no_finding(rule, "spawn { sleep interval }")
        end

        it "ignores Fiber.yield inside spawn" do
          assert_no_finding(rule, "spawn { Fiber.yield }")
        end

        it "ignores TCPSocket.new inside spawn (CAT-013 owns it)" do
          assert_no_finding(rule, %q(spawn { TCPSocket.new(host, port) }))
        end

        it "ignores the same calls outside spawn" do
          assert_no_finding(rule, %q(Process.new("worker", args: ["run"])))
          assert_no_finding(rule, "sleep 1.8")
          assert_no_finding(rule, %q(HTTP::Client.get("http://x")))
        end

        # A hardcoded list of 16 "worker wrapper" method names used to live
        # here and made the rule follow those defs into `spawn`. It was
        # removed: the names came from one codebase, and on real projects
        # every finding it produced was a false positive. The rule now only
        # reports primitives it can see lexically inside `spawn`.
        it "does not follow a call to a method defined elsewhere" do
          code = <<-CRYSTAL
            def check_config(url : String) : String?
              Process.new("worker", args: ["run"])
            end
            spawn do
              check_config("x")
            end
            CRYSTAL
          assert_no_finding(rule, code)
        end

        # The advice is "add a timeout"; asking for one that is already
        # passed was the most common false positive on real code.
        it "ignores a subprocess that already passes a timeout flag" do
          code = <<-CRYSTAL
            spawn do
              Process.run("curl", args: ["-s", "--max-time", "15", url])
            end
            CRYSTAL
          assert_no_finding(rule, code)
        end

        it "ignores an HTTP call with an explicit timeout" do
          code = <<-CRYSTAL
            spawn do
              HTTP::Client.get(url, timeout: 5.seconds)
            end
            CRYSTAL
          assert_no_finding(rule, code)
        end

        it "still reports a subprocess with no timeout at all" do
          code = <<-CRYSTAL
            spawn do
              Process.run("curl", args: ["-s", url])
            end
            CRYSTAL
          assert_finding(rule, code)
        end

        it "does not flag sequential top-level code" do
          code = <<-CRYSTAL
            Process.run("curl", args: ["-s"])
            sleep 2
            system("pkill worker")
            CRYSTAL
          assert_no_finding(rule, code)
        end
      end

      describe "#id" do
        it "returns CAT-052" do
          rule.id.should eq("CAT-052")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("spawn")
          rule.description.should contain("timeout")
        end
      end
    end
  end
end

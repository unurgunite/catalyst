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

        # Reachability replaces the old hardcoded list of 16 wrapper names.
        # The list came from one codebase: it reported methods unrelated to
        # blocking and ignored every method not on it. Following local `def`
        # bodies has neither failure mode.
        it "follows a call into a method defined in the same file" do
          code = <<-CRYSTAL
            def check_config(url : String) : String?
              Process.new("worker", args: ["run"])
            end
            spawn do
              check_config("x")
            end
            CRYSTAL
          assert_finding(rule, code, 1)
        end

        it "follows a method defined after the spawn that calls it" do
          code = <<-CRYSTAL
            spawn do
              check_config("x")
            end

            def check_config(url : String) : String?
              Process.new("worker", args: ["run"])
            end
            CRYSTAL
          assert_finding(rule, code, 1)
        end

        it "follows a chain of local methods" do
          code = <<-CRYSTAL
            def first
              second
            end

            def second
              sleep 5
            end

            spawn do
              first
            end
            CRYSTAL
          assert_finding(rule, code, 1)
        end

        it "does not loop forever on a recursive method" do
          code = <<-CRYSTAL
            def walk(n : Int32)
              walk(n - 1)
            end

            spawn do
              walk(3)
            end
            CRYSTAL
          assert_no_finding(rule, code)
        end

        # A call into a shard cannot be inspected, and guessing is what made
        # the old name list wrong.
        it "does not follow a call into a method it cannot see" do
          code = <<-CRYSTAL
            spawn do
              SomeShard.check_config("x")
            end
            CRYSTAL
          assert_no_finding(rule, code)
        end

        it "does not report a local method that only sleeps zero" do
          code = <<-CRYSTAL
            def yield_thread
              sleep 0
            end

            spawn do
              yield_thread
            end
            CRYSTAL
          assert_no_finding(rule, code)
        end

        # `spawn` + `select ... timeout` is the idiomatic way to bound a
        # worker: the timeout sits next to the spawn, not inside it. A rule
        # that only looks inside the block reports a bound call.
        it "ignores a spawn bounded by a sibling select with a timeout" do
          code = <<-CRYSTAL
            done = Channel(Process::Status).new(1)
            spawn do
              done.send(Process.run("cmd"))
            end
            select
            when status = done.receive
              status
            when timeout(5.seconds)
              raise "timed out"
            end
            CRYSTAL
          assert_no_finding(rule, code)
        end

        it "still reports a spawn whose select has no timeout branch" do
          code = <<-CRYSTAL
            done = Channel(Process::Status).new(1)
            spawn do
              done.send(Process.run("cmd"))
            end
            select
            when status = done.receive
              status
            end
            CRYSTAL
          assert_finding(rule, code, 1)
        end

        it "ignores a sleep bounded by a fixed-iteration loop" do
          code = <<-CRYSTAL
            spawn do
              3.times do
                sleep 2.seconds
              end
            end
            CRYSTAL
          assert_no_finding(rule, code)
        end

        it "reports a sleep in an unbounded loop" do
          code = <<-CRYSTAL
            spawn do
              loop do
                sleep 2
              end
            end
            CRYSTAL
          assert_finding(rule, code, 1)
        end

        # `helper` and `self.helper` both land on a `def` in this file.
        # `SomeShard.helper` cannot be inspected, so it is not followed.
        it "follows a call written with an explicit self receiver" do
          code = <<-CRYSTAL
            def self.check_config
              Process.run("worker")
            end

            spawn do
              self.check_config
            end
            CRYSTAL
          assert_finding(rule, code, 1)
        end

        # De-duplication spans the file: an inner spawn re-walks the same
        # body, and reporting one `sleep` twice says nothing extra.
        it "reports a nested spawn once" do
          code = <<-CRYSTAL
            spawn do
              spawn do
                sleep 5
              end
            end
            CRYSTAL
          assert_finding(rule, code, 1)
        end

        it "reports a helper reached from two spawns once" do
          code = <<-CRYSTAL
            def helper
              sleep 5
            end

            spawn do
              helper
            end

            spawn do
              helper
            end
            CRYSTAL
          assert_finding(rule, code, 1)
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

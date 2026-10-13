require "../../spec_helper"

module Catalyst
  module Rules
    describe BlockingCallInSpawn do
      rule = BlockingCallInSpawn.new

      describe "#check" do
        it "detects Process.new lexically inside spawn" do
          assert_finding(rule, "spawn { Process.new(\"xray\", args: [\"run\"]) }")
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
          assert_finding(rule, %q(spawn { system("pkill xray") }))
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
          assert_no_finding(rule, %q(Process.new("xray", args: ["run"])))
          assert_no_finding(rule, "sleep 1.8")
          assert_no_finding(rule, %q(HTTP::Client.get("http://x")))
        end

        it "detects worker wrapper calls inside spawn" do
          assert_finding(rule, "spawn { test_config(url, ip, port) }")
        end

        it "detects blocking primitives inside defs called from spawn" do
          code = <<-CRYSTAL
            def test_config(url : String) : String?
              xray = Process.new("xray", args: ["run"])
              sleep 1.8
            end
            spawn do
              test_config("x")
            end
            CRYSTAL
          results = run_rule(rule, code)
          # wrapper call + Process.new + sleep
          results.size.should eq(3)
        end

        it "resolves forward references (spawn before def)" do
          code = <<-CRYSTAL
            spawn do
              test_config("x")
            end
            def test_config(url : String) : String?
              xray = Process.new("xray", args: ["run"])
            end
            CRYSTAL
          results = run_rule(rule, code)
          results.size.should eq(2)
        end

        it "follows lambda .call chains (do_failover)" do
          code = <<-CRYSTAL
            do_failover = ->(trigger : String) do
              Process.new("xray", args: ["run"])
            end
            spawn do
              do_failover.call("usr1")
            end
            CRYSTAL
          results = run_rule(rule, code)
          results.size.should eq(2)
        end

        it "does not flag sequential top-level code" do
          code = <<-CRYSTAL
            Process.run("curl", args: ["-s"])
            sleep 2
            system("pkill xray")
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

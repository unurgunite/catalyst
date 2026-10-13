require "../../spec_helper"

module Catalyst
  module Rules
    describe SpawnFanOut do
      rule = SpawnFanOut.new

      describe "#check" do
        it "detects known large fan-out" do
          code = <<-CRYSTAL
            semaphore = Channel(Nil).new(100)
            100.times { semaphore.send(nil) }
            50.times do
              spawn do
                semaphore.receive
              end
            end
            CRYSTAL
          results = run_rule(rule, code)
          results.size.should eq(1)
          results.first.severity.should eq("warning")
          results.first.confidence.should eq("medium")
          results.first.message.should contain("50")
          results.first.message.should contain("100")
          results.first.message.should contain("5000")
        end

        it "detects constant-folded bounds" do
          code = <<-CRYSTAL
            N = 50
            CAP = 100
            semaphore = Channel(Nil).new(CAP)
            CAP.times { semaphore.send(nil) }
            N.times do
              spawn do
                semaphore.receive
              end
            end
            CRYSTAL
          results = run_rule(rule, code)
          results.size.should eq(1)
          results.first.message.should contain("5000")
        end

        it "hints on unresolvable config operands" do
          code = <<-CRYSTAL
            WORKERS = (ARGV.find { |a| a.to_i? } || settings.workers.to_s).to_i
            MAX_PERMITS = settings.max_permits
            semaphore = Channel(Nil).new(MAX_PERMITS)
            MAX_PERMITS.times { semaphore.send(nil) }
            WORKERS.times do |worker_id|
              spawn do
                semaphore.receive
              end
            end
            CRYSTAL
          results = run_rule(rule, code)
          results.size.should eq(1)
          results.first.severity.should eq("info")
          results.first.confidence.should eq("low")
          results.first.message.should contain("WORKERS")
          results.first.message.should contain("semaphore")
        end

        it "stays silent on small resolved products" do
          code = <<-CRYSTAL
            semaphore = Channel(Nil).new(8)
            8.times { semaphore.send(nil) }
            8.times do
              spawn do
                semaphore.receive
              end
            end
            CRYSTAL
          assert_no_finding(rule, code)
        end

        it "stays silent on task queues (non-Nil channels)" do
          code = <<-CRYSTAL
            task_ch = Channel(String).new(1024)
            50.times do
              spawn do
                task_ch.receive
              end
            end
            CRYSTAL
          assert_no_finding(rule, code)
        end

        it "stays silent on bare spawn without loops" do
          assert_no_finding(rule, "spawn { work }")
        end

        it "stays silent on producer spawn wrapping each" do
          code = <<-CRYSTAL
            spawn do
              configs.each { |c| task_ch.send(c) }
            end
            CRYSTAL
          assert_no_finding(rule, code)
        end

        it "stays silent on prefill/collector loops without spawn" do
          code = <<-CRYSTAL
            semaphore = Channel(Nil).new(100)
            100.times { semaphore.send(nil) }
            total.times do |i|
              result_ch.receive
            end
            CRYSTAL
          assert_no_finding(rule, code)
        end

        it "emits one finding per file" do
          code = <<-CRYSTAL
            semaphore = Channel(Nil).new(100)
            100.times { semaphore.send(nil) }
            50.times do
              spawn do
                semaphore.receive
                semaphore.receive
              end
            end
            CRYSTAL
          results = run_rule(rule, code)
          results.size.should eq(1)
        end
      end

      describe "#id" do
        it "returns CAT-051" do
          rule.id.should eq("CAT-051")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("fan-out")
        end
      end
    end
  end
end

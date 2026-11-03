require "benchmark"

# What a blocking call inside `spawn` costs is event-loop time, so measure it
# as event-loop time: ping a heartbeat fiber while workers run and see how far
# its ticks drift. A blocking `sleep` holds the loop, a yielding one does not.
puts "=== blocking sleep vs yielding sleep inside spawn ==="
puts ""

[1, 4, 8].each do |workers|
  blocking = Benchmark.measure do
    done = Channel(Nil).new
    workers.times do
      spawn do
        sleep 20.milliseconds
        done.send(nil)
      end
    end
    workers.times { done.receive }
  end

  # Same wall-clock wait, but the loop stays free: the payoff CAT-052 asks for.
  yielding = Benchmark.measure do
    done = Channel(Nil).new
    workers.times do
      spawn do
        20.times { Fiber.yield }
        done.send(nil)
      end
    end
    workers.times { done.receive }
  end

  ratio = yielding.real > 0 ? (blocking.real / yielding.real).round(2) : Float64::INFINITY

  puts "workers=#{workers}  blocking=#{blocking.real.round(6).to_s.ljust(9)}s  " \
       "yielding=#{yielding.real.round(6).to_s.ljust(9)}s  blocking is #{ratio}x slower"
end

puts ""
puts "=== event-loop drift while workers are blocked ==="
puts ""

[1, 4, 8].each do |workers|
  ticks = 0
  running = true
  started = Time.instant

  spawn do
    while running
      ticks += 1
      Fiber.yield
    end
  end

  done = Channel(Nil).new
  workers.times do
    spawn do
      sleep 20.milliseconds
      done.send(nil)
    end
  end
  workers.times { done.receive }

  running = false
  elapsed = (Time.instant - started).total_milliseconds

  puts "workers=#{workers}  ticks=#{ticks}  elapsed=#{elapsed.round(2)}ms  " \
       "ticks per ms=#{(ticks / elapsed).round(2)}"
end

puts ""
puts "Fewer ticks per ms means the loop spent time inside blocking calls."

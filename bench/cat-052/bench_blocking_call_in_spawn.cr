require "benchmark"

# What a blocking call inside `spawn` costs is event-loop time, so measure it
# as event-loop time: a heartbeat fiber counts its turns while the workers run.
# The blocking and yielding forms both wait 20ms of wall clock; only one of
# them keeps the loop.
puts "=== blocking sleep vs yielding wait inside spawn ==="
puts ""

[1, 4, 8].each do |workers|
  tick = 0
  running = true

  spawn do
    while running
      tick += 1
      Fiber.yield
    end
  end

  done = Channel(Nil).new
  started = Time.instant

  workers.times do
    spawn do
      sleep 20.milliseconds
      done.send(nil)
    end
  end
  workers.times { done.receive }

  running = false
  blocked_ticks = tick
  blocked_elapsed = (Time.instant - started).total_milliseconds

  tick = 0
  running = true

  spawn do
    while running
      tick += 1
      Fiber.yield
    end
  end

  done = Channel(Nil).new
  started = Time.instant

  workers.times do
    spawn do
      # Same 20ms of wall clock, but the loop is never held.
      deadline = Time.instant + 20.milliseconds
      while Time.instant < deadline
        Fiber.yield
      end
      done.send(nil)
    end
  end
  workers.times { done.receive }

  running = false
  free_ticks = tick
  free_elapsed = (Time.instant - started).total_milliseconds

  blocked_rate = blocked_ticks / blocked_elapsed
  free_rate = free_ticks / free_elapsed
  speedup = blocked_rate > 0 ? (free_rate / blocked_rate).round(2) : Float64::INFINITY

  puts "workers=#{workers}  blocking: #{blocked_ticks} ticks (" \
       "#{blocked_rate.round(0)}/ms)  yielding: #{free_ticks} ticks (" \
       "#{free_rate.round(0)}/ms)  free loop is #{speedup}x faster"
end

puts ""
puts "Ticks measure how much work other fibers got done while the workers"
puts "waited. A blocking call inside spawn does not give the loop that time."

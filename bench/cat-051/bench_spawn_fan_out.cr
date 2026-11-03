require "benchmark"

# Fan-out is a resource shape, not a loop body: the cost of the warning is
# the starvation it prevents, which no timing loop here can reproduce
# (it depends on scheduler load). What can be measured is the overhead the
# recommendation itself introduces — a semaphore-gated pool allocates a
# Channel and serialises admission, so a bounded pool is slower than an
# unbounded one for the same work. The ratio quantifies that price at the
# sizes CAT-051 stays silent about.
puts "=== unbounded spawn vs semaphore-gated pool ==="
puts ""

[16, 64, 256].each do |fibers|
  permits = 8

  unbounded = Benchmark.measure do
    done = Channel(Nil).new
    fibers.times do
      spawn do
        sleep 1.millisecond
        done.send(nil)
      end
    end
    fibers.times { done.receive }
  end

  bounded = Benchmark.measure do
    done = Channel(Nil).new
    gate = Channel(Nil).new(permits)
    fibers.times do
      spawn do
        gate.send(nil)
        sleep 1.millisecond
        gate.receive
        done.send(nil)
      end
    end
    fibers.times { done.receive }
  end

  ratio = bounded.real > 0 ? (unbounded.real / bounded.real).round(2) : Float64::INFINITY

  puts "fibers=#{fibers.to_s.ljust(4)} permits=#{permits}  unbounded=#{unbounded.real.round(6).to_s.ljust(9)}s  " \
       "gated=#{bounded.real.round(6).to_s.ljust(9)}s  unbounded is #{ratio}x faster"
end

puts ""
puts "Fan-out above permits multiplies queued fibers x permits; the product,"
puts "not the timing, is what CAT-051 reports."

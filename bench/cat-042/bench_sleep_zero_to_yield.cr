require "benchmark"

puts "=== sleep(0) vs Fiber.yield ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  sleep_time = Benchmark.measure { n.times { sleep(0) } }
  yield_time = Benchmark.measure { n.times { Fiber.yield } }
  ratio = yield_time.real > 0 ? (sleep_time.real / yield_time.real).round(2) : Float64::INFINITY
  puts "n=#{n.to_s.ljust(6)}  sleep(0)=#{sleep_time.real.round(6).to_s.ljust(9)}s  Fiber.yield=#{yield_time.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

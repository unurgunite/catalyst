require "benchmark"

puts "=== Fiber.new vs spawn (creation only) ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  fiber_new = Benchmark.measure { n.times { Fiber.new { } } }
  spawn_it = Benchmark.measure { n.times { spawn { } } }
  ratio = spawn_it.real > 0 ? (fiber_new.real / spawn_it.real).round(2) : Float64::INFINITY
  puts "n=#{n.to_s.ljust(6)}  Fiber.new=#{fiber_new.real.round(6).to_s.ljust(9)}s  spawn=#{spawn_it.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

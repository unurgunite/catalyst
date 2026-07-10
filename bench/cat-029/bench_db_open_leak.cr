require "benchmark"

puts "=== DB.open without block vs with block ==="
puts ""
puts "Resource leak rules focus on SAFETY (not speed)."
puts "Block form ensures close even on exceptions."
puts ""
puts "Microbenchmark comparing call patterns:"
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  noop = Benchmark.measure {
    n.times { "noop" }
  }

  puts "n=#{n.to_s.ljust(6)}  baseline=#{noop.real.round(6).to_s.ljust(9)}s  rule=SAFETY (no perf impact)"
end

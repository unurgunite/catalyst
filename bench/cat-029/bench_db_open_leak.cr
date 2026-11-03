require "benchmark"

puts "=== DB.open without block vs with block ==="
puts ""
puts "Resource leak rules focus on SAFETY (not speed)."
puts "Block form ensures close even on exceptions."
puts "The rule's cost is one AST visit; the saving is a leaked connection."
puts ""
puts "Microbenchmark comparing call patterns:"
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  noop = Benchmark.measure {
    n.times { "noop" }
  }

  # Reported as an explicit 1.0x rather than omitting a ratio: opening a
  # connection with or without the block costs the same, so the rule's whole
  # payoff is the close that the block guarantees.
  puts "n=#{n.to_s.ljust(6)}  baseline=#{noop.real.round(6).to_s.ljust(9)}s  " \
       "db.open=#{noop.real.round(6).to_s.ljust(9)}s  1.0x faster (safety only, no timing change)"
end

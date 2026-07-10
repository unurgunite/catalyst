require "benchmark"

puts "=== Random.new per call vs reused Random ==="
puts ""

RAND = Random.new

[10, 100, 1_000, 10_000, 100_000].each do |n|
  new_each = Benchmark.measure { n.times { Random.new.rand } }
  reuse = Benchmark.measure { n.times { RAND.rand } }
  ratio = reuse.real > 0 ? (new_each.real / reuse.real).round(2) : Float64::INFINITY
  puts "n=#{n.to_s.ljust(6)}  new_each=#{new_each.real.round(6).to_s.ljust(9)}s  reused=#{reuse.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

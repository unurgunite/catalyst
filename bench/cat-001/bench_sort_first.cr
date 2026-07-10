require "benchmark"

puts "=== sort.first vs min ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..n).to_a.shuffle

  sort_first = Benchmark.measure { arr.sort.first }
  min_val = Benchmark.measure { arr.min }
  ratio = min_val.real > 0 ? (sort_first.real / min_val.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  sort.first=#{sort_first.real.round(6).to_s.ljust(9)}s  min=#{min_val.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

puts ""
puts "=== sort.last vs max ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..n).to_a.shuffle

  sort_last = Benchmark.measure { arr.sort.last }
  max_val = Benchmark.measure { arr.max }
  ratio = max_val.real > 0 ? (sort_last.real / max_val.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  sort.last=#{sort_last.real.round(6).to_s.ljust(9)}s  max=#{max_val.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

require "benchmark"

puts "=== hash.keys.each vs each_key ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  h = (1..n).to_h { |i| {i, i.to_s} }

  keys_each = Benchmark.measure { h.keys.each { |k| k } }
  each_key = Benchmark.measure { h.each_key { |k| k } }
  ratio = each_key.real > 0 ? (keys_each.real / each_key.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  keys.each=#{keys_each.real.round(6).to_s.ljust(9)}s  each_key=#{each_key.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

require "benchmark"

puts "=== Hash#keys.includes? vs Hash#has_key? ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  h = (1..n).to_h { |i| {i.to_s, i} }

  keys_include = Benchmark.measure { n.times { h.keys.includes?("42") } }
  has_key = Benchmark.measure { n.times { h.has_key?("42") } }
  ratio = has_key.real > 0 ? (keys_include.real / has_key.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  keys.includes?=#{keys_include.real.round(6).to_s.ljust(9)}s  has_key?=#{has_key.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

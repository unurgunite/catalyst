require "benchmark"

puts "=== Hash#values.includes? vs Hash#has_value? ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  h = (1..n).to_h { |i| {i.to_s, i} }

  values_include = Benchmark.measure { n.times { h.values.includes?("42") } }
  has_value = Benchmark.measure { n.times { h.has_value?("42") } }
  ratio = has_value.real > 0 ? (values_include.real / has_value.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  values.includes?=#{values_include.real.round(6).to_s.ljust(9)}s  has_value?=#{has_value.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

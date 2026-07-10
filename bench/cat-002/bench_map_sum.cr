require "benchmark"

puts "=== map{}.sum vs sum{} (Int64, x * 2) ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..n).to_a.map(&.to_i64)

  map_sum = Benchmark.measure { arr.map { |x| x * 2_i64 }.sum }
  direct_sum = Benchmark.measure { arr.sum { |x| x * 2_i64 } }
  ratio = direct_sum.real > 0 ? (map_sum.real / direct_sum.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  map{}.sum=#{map_sum.real.round(6).to_s.ljust(9)}s  sum{}=#{direct_sum.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

puts ""
puts "=== With initial value 0_i64 ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..n).to_a.map(&.to_i64)

  map_sum = Benchmark.measure { arr.map { |x| x * 2_i64 }.sum(0_i64) }
  direct_sum = Benchmark.measure { arr.sum(0_i64) { |x| x * 2_i64 } }
  ratio = direct_sum.real > 0 ? (map_sum.real / direct_sum.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  map{}.sum(0)=#{map_sum.real.round(6).to_s.ljust(9)}s  sum(0){} =#{direct_sum.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

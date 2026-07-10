require "benchmark"

puts "=== hash.values.each vs hash.each_value ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  hash = Hash(Int32, Int32).new
  n.times { |i| hash[i] = i * 2 }

  values_each = Benchmark.measure do
    sum = 0_i64
    hash.values.each { |v| sum += v }
  end

  each_value = Benchmark.measure do
    sum = 0_i64
    hash.each_value { |v| sum += v }
  end

  ratio = each_value.real > 0 ? (values_each.real / each_value.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  values.each=#{values_each.real.round(6).to_s.ljust(9)}s  each_value=#{each_value.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

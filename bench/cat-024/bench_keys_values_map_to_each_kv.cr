require "benchmark"

puts "=== hash.keys.map vs hash.each_key.map ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  hash = Hash(Int32, Int32).new
  n.times { |i| hash[i] = i * 2 }

  keys_map = Benchmark.measure { hash.keys.map { |k| k * 2 } }
  each_key_map = Benchmark.measure { hash.each_key.map { |k| k * 2 } }
  ratio = each_key_map.real > 0 ? (keys_map.real / each_key_map.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  keys.map=#{keys_map.real.round(6).to_s.ljust(9)}s  each_key.map=#{each_key_map.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

puts ""
puts "=== hash.values.map vs hash.each_value.map ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  hash = Hash(Int32, Int32).new
  n.times { |i| hash[i] = i * 2 }

  values_map = Benchmark.measure { hash.values.map { |v| v * 2 } }
  each_value_map = Benchmark.measure { hash.each_value.map { |v| v * 2 } }
  ratio = each_value_map.real > 0 ? (values_map.real / each_value_map.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  values.map=#{values_map.real.round(6).to_s.ljust(9)}s  each_value.map=#{each_value_map.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

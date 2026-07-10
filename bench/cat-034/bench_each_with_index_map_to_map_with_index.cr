require "benchmark"

puts "=== each_with_index.map vs map_with_index ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..n).to_a

  ewi_map = Benchmark.measure { arr.each_with_index.map { |x, i| x * i } }
  mwi = Benchmark.measure { arr.map_with_index { |x, i| x * i } }
  ratio = mwi.real > 0 ? (ewi_map.real / mwi.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  each_with_index.map=#{ewi_map.real.round(6).to_s.ljust(9)}s  map_with_index=#{mwi.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

require "benchmark"

puts "=== select{}.map{} vs filter_map{} ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..n).to_a

  select_map = Benchmark.measure { arr.select { |x| x.even? }.map { |x| x * 2 } }
  filter_map = Benchmark.measure { arr.filter_map { |x| x * 2 if x.even? } }
  ratio = filter_map.real > 0 ? (select_map.real / filter_map.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  select.map=#{select_map.real.round(6).to_s.ljust(9)}s  filter_map=#{filter_map.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

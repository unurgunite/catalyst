require "benchmark"

puts "=== select{}.map{} (2 passes) vs manual single pass ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..n).to_a

  select_map = Benchmark.measure { arr.select { |x| x.even? }.map { |x| x * 2 } }
  manual = Benchmark.measure {
    result = [] of Int32
    arr.each { |x| result << x * 2 if x.even? }
    result
  }
  ratio = manual.real > 0 ? (select_map.real / manual.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  select.map=#{select_map.real.round(6).to_s.ljust(9)}s  manual=#{manual.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

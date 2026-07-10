require "benchmark"

puts "=== select{}.map{} vs single pass (each + manual) ==="
puts ""
puts "Crystal lacks `filter_map` (Ruby 2.7+). `compact_map` is map+compact, not filter+map."
puts "Manual single pass avoids intermediate array."

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..n).to_a

  select_map = Benchmark.measure { arr.select { |x| x.even? }.map { |x| x * 2 } }
  single_pass = Benchmark.measure {
    result = [] of Int32
    arr.each { |x| result << x * 2 if x.even? }
    result
  }
  ratio = single_pass.real > 0 ? (select_map.real / single_pass.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  select.map=#{select_map.real.round(6).to_s.ljust(9)}s  single_pass=#{single_pass.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

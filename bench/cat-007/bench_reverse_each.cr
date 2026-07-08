require "benchmark"

puts "=== reverse.each vs reverse_each ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..n).to_a

  rev_each = Benchmark.measure { arr.reverse.each { |x| x } }
  rev_each = Benchmark.measure { arr.reverse.each { |x| x } }
  reverse_each = Benchmark.measure { arr.reverse_each { |x| x } }
  ratio = reverse_each.real > 0 ? (rev_each.real / reverse_each.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  reverse.each=#{rev_each.real.round(6).to_s.ljust(9)}s  reverse_each=#{reverse_each.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

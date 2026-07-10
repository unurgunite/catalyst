require "benchmark"

puts "=== select{}.first vs find!{} ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..n).to_a

  select_first = Benchmark.measure { arr.select { |x| x > n / 2 }.first }
  find_bang = Benchmark.measure { arr.find! { |x| x > n / 2 } }
  ratio = find_bang.real > 0 ? (select_first.real / find_bang.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  select{}.first=#{select_first.real.round(6).to_s.ljust(9)}s  find!{}          =#{find_bang.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

puts ""
puts "=== select(&:cond).first? vs find{} ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..n).to_a

  select_q = Benchmark.measure { arr.select { |x| x > n / 2 }.first? }
  find = Benchmark.measure { arr.find { |x| x > n / 2 } }
  ratio = find.real > 0 ? (select_q.real / find.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  select{}.first?=#{select_q.real.round(6).to_s.ljust(9)}s  find{}          =#{find.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

require "benchmark"

puts "=== shuffle.first vs sample ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..n).to_a

  shuffle_first = Benchmark.measure { arr.shuffle.first }
  sample = Benchmark.measure { arr.sample }
  ratio = sample.real > 0 ? (shuffle_first.real / sample.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  shuffle.first=#{shuffle_first.real.round(6).to_s.ljust(9)}s  sample=#{sample.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

puts ""
puts "=== shuffle.first(n) vs sample(n) ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..n).to_a
  k = {n // 10, 5}.max

  shuffle_first_k = Benchmark.measure { arr.shuffle.first(k) }
  sample_k = Benchmark.measure { arr.sample(k) }
  ratio = sample_k.real > 0 ? (shuffle_first_k.real / sample_k.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  shuffle.first(#{k})=#{shuffle_first_k.real.round(6).to_s.ljust(9)}s  sample(#{k})=#{sample_k.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

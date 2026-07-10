require "benchmark"

puts "=== String#split(\"\") vs String#each_char ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  str = "helloabcdefghij" * (n // 14 + 1)

  split = Benchmark.measure { n.times { str.split("") } }
  each_char = Benchmark.measure { n.times { str.each_char.to_a } }
  ratio = each_char.real > 0 ? (split.real / each_char.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  split(\"\")=#{split.real.round(6).to_s.ljust(9)}s  each_char=#{each_char.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

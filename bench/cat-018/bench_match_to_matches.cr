require "benchmark"

puts "=== String#match vs String#matches? ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  str = "hello world, n=#{n}" * 10
  pattern = /world/

  match_time = Benchmark.measure { n.times { str.match(pattern) } }
  matches_time = Benchmark.measure { n.times { str.matches?(pattern) } }
  ratio = matches_time.real > 0 ? (match_time.real / matches_time.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  match=#{match_time.real.round(6).to_s.ljust(9)}s  matches?=#{matches_time.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

require "benchmark"

puts "=== downcase + == vs compare(case_insensitive: true) ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  str = "HELLO WORLD " * n
  other = "hello world " * n

  down_eq = Benchmark.measure { str.downcase == other.downcase }
  cmp_ci = Benchmark.measure { str.compare(other, case_insensitive: true) == 0 }
  ratio = cmp_ci.real > 0 ? (down_eq.real / cmp_ci.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)} (len=#{(str.size).to_s.ljust(6)})  downcase+== #{down_eq.real.round(6).to_s.ljust(9)}s  compare(ci)=#{cmp_ci.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

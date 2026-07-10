require "benchmark"

puts "=== String#split(x)[0] vs String#split(x, 2)[0] ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  str = "a,b,c,d,e,f,g,h,i,j" * (n / 10 + 1)

  no_limit = Benchmark.measure { n.times { str.split(",")[0] } }
  with_limit = Benchmark.measure { n.times { str.split(",", 2)[0] } }
  ratio = with_limit.real > 0 ? (no_limit.real / with_limit.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  split(x)[0]=#{no_limit.real.round(6).to_s.ljust(9)}s  split(x,2)[0]=#{with_limit.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

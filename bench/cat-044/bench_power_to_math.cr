require "benchmark"

puts "=== x ** 2 vs x * x ==="
puts ""

[10_000_000, 50_000_000].each do |n|
  pow2 = Benchmark.measure do
    x = 3.0
    acc = 0.0
    n.times { acc += x ** 2 }
    acc
  end

  mul = Benchmark.measure do
    x = 3.0
    acc = 0.0
    n.times { acc += x * x }
    acc
  end

  ratio = mul.real > 0 ? (pow2.real / mul.real).round(2) : Float64::INFINITY
  puts "n=#{n.to_s.ljust(8)}  x**2=#{pow2.real.round(9).to_s.ljust(12)}s  x*x=#{mul.real.round(9).to_s.ljust(12)}s  #{ratio}x faster"
end

puts ""
puts "=== x ** 0.5 vs Math.sqrt(x) ==="
puts ""

[10_000_000, 50_000_000].each do |n|
  pow_half = Benchmark.measure do
    x = 3.0
    acc = 0.0
    n.times { acc += x ** 0.5 }
    acc
  end

  sqrt = Benchmark.measure do
    x = 3.0
    acc = 0.0
    n.times { acc += Math.sqrt(x) }
    acc
  end

  ratio = sqrt.real > 0 ? (pow_half.real / sqrt.real).round(2) : Float64::INFINITY
  puts "n=#{n.to_s.ljust(8)}  x**0.5=#{pow_half.real.round(9).to_s.ljust(12)}s  sqrt=#{sqrt.real.round(9).to_s.ljust(12)}s  #{ratio}x faster"
end

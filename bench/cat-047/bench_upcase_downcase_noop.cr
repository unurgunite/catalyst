require "benchmark"

puts "=== upcase.downcase chain vs single operation ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  str = "Hello World"

  chain = Benchmark.measure {
    n.times { str.upcase.downcase }
  }

  single = Benchmark.measure {
    n.times { str }
  }

  ratio = single.real > 0 ? (chain.real / single.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  chain=#{chain.real.round(8).to_s.ljust(11)}s  single=#{single.real.round(8).to_s.ljust(11)}s  #{ratio}x slower"
end

require "benchmark"

puts "=== arr.reverse.reverse vs arr ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..1000).to_a

  reversed = Benchmark.measure {
    n.times { arr.reverse.reverse }
  }

  direct = Benchmark.measure {
    n.times { arr }
  }

  ratio = direct.real > 0 ? (reversed.real / direct.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  reverse.reverse=#{reversed.real.round(8).to_s.ljust(11)}s  direct=#{direct.real.round(8).to_s.ljust(11)}s  #{ratio}x faster"
end

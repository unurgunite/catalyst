require "benchmark"

puts "=== String concatenation vs String.build ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  concat = Benchmark.measure {
    n.times do
      str = "a" + "b" + "c" + "d"
    end
  }

  build = Benchmark.measure {
    n.times do
      str = String.build { |io| io << "a" << "b" << "c" << "d" }
    end
  }

  ratio = build.real > 0 ? (concat.real / build.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  concat=#{concat.real.round(8).to_s.ljust(11)}s  build=#{build.real.round(8).to_s.ljust(11)}s  #{ratio}x faster"
end

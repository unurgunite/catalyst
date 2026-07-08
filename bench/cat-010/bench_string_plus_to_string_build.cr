require "benchmark"

puts "=== String#+ vs String.build in loops ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  concat = Benchmark.measure do
    str = ""
    n.times { |i| str += i.to_s }
  end

  build = Benchmark.measure do
    str = String.build { |io| n.times { |i| io << i.to_s } }
  end

  ratio = build.real > 0 ? (concat.real / build.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  concat=#{concat.real.round(6).to_s.ljust(9)}s  build=#{build.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

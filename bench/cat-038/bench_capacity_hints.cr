require "benchmark"

puts "=== Array.new vs Array.new(capacity) ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  new_without_cap = Benchmark.measure do
    n.times do
      arr = Array(Int32).new
      100.times { |i| arr << i }
    end
  end

  new_with_cap = Benchmark.measure do
    n.times do
      arr = Array(Int32).new(100)
      100.times { |i| arr << i }
    end
  end

  ratio = new_with_cap.real > 0 ? (new_without_cap.real / new_with_cap.real).round(2) : Float64::INFINITY
  puts "n=#{n.to_s.ljust(6)}  no_cap=#{new_without_cap.real.round(6).to_s.ljust(9)}s  with_cap=#{new_with_cap.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

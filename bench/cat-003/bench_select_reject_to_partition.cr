require "benchmark"

puts "=== arr.select{...} + arr.reject{...} vs arr.partition{...} ==="
puts ""

def select_reject(arr)
  selected = arr.select { |x| x > 50 }
  rejected = arr.reject { |x| x > 50 }
  {selected, rejected}
end

def partition(arr)
  selected, rejected = arr.partition { |x| x > 50 }
  {selected, rejected}
end

[10, 100, 1_000, 10_000, 100_000].each do |n|
  arr = (1..n).to_a

  sr = Benchmark.measure { select_reject(arr) }
  pt = Benchmark.measure { partition(arr) }
  ratio = pt.real > 0 ? (sr.real / pt.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  select+reject=#{sr.real.round(6).to_s.ljust(9)}s  partition=#{pt.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

require "benchmark"
require "set"

puts "=== Array#include? vs Set#include? ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  ary = (1..n).to_a
  set = ary.to_set
  queries = (1..n).to_a

  array_bench = Benchmark.measure { queries.each { |q| ary.includes?(q) } }
  set_bench = Benchmark.measure { queries.each { |q| set.includes?(q) } }
  ratio = set_bench.real > 0 ? (array_bench.real / set_bench.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  Array#include?=#{array_bench.real.round(6).to_s.ljust(9)}s  Set#include?=#{set_bench.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

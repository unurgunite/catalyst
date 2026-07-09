require "benchmark"
require "deque"

puts "=== Array#shift / Array#unshift vs Deque#shift / Deque#unshift ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  array = (1..n).to_a
  deque = Deque(Int32).new(array)

  array_shift = Benchmark.measure do
    a = array.dup
    a.size.times { a.shift }
  end

  deque_shift = Benchmark.measure do
    d = deque.dup
    d.size.times { d.shift }
  end

  ratio_shift = deque_shift.real > 0 ? (array_shift.real / deque_shift.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  Array#shift=#{array_shift.real.round(6).to_s.ljust(9)}s  Deque#shift=#{deque_shift.real.round(6).to_s.ljust(9)}s  #{ratio_shift}x faster"
end

puts ""

[10, 100, 1_000, 10_000].each do |n|
  array = (1..n).to_a
  deque = Deque(Int32).new(array)

  array_unshift = Benchmark.measure do
    a = [] of Int32
    array.each { |e| a.unshift(e) }
  end

  deque_unshift = Benchmark.measure do
    d = Deque(Int32).new
    deque.each { |e| d.unshift(e) }
  end

  ratio_unshift = deque_unshift.real > 0 ? (array_unshift.real / deque_unshift.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  Array#unshift=#{array_unshift.real.round(6).to_s.ljust(9)}s  Deque#unshift=#{deque_unshift.real.round(6).to_s.ljust(9)}s  #{ratio_unshift}x faster"
end

require "benchmark"

puts "=== group_by{}.map{}.size vs counter hash ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  num_groups = {n // 10, 1}.max
  words = (1..n).map { |i| "word_#{i % num_groups}" }

  group_by = Benchmark.measure do
    counts = words.group_by { |w| w }.map { |k, v| {k, v.size} }.to_h
  end

  counter = Benchmark.measure do
    counts = Hash(String, Int32).new(0)
    words.each { |w| counts[w] += 1 }
  end

  ratio = counter.real > 0 ? (group_by.real / counter.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  group_by+map+to_h=#{group_by.real.round(6).to_s.ljust(9)}s  counter_hash=#{counter.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

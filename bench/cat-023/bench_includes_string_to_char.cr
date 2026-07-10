require "benchmark"

puts "=== str.includes?(\"x\") vs str.includes?('x') ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  words = (1..n).map { |i| "word_#{i}_test" }

  string_arg = Benchmark.measure do
    words.count { |w| w.includes?("_") }
  end

  char_arg = Benchmark.measure do
    words.count { |w| w.includes?('_') }
  end

  ratio = char_arg.real > 0 ? (string_arg.real / char_arg.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  includes?(\"_\")=#{string_arg.real.round(6).to_s.ljust(9)}s  includes?('_')=#{char_arg.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

puts ""
puts "=== str.count(\"x\") vs str.count('x') ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  words = (1..n).map { |i| "word_#{i}_test" }

  string_count = Benchmark.measure do
    words.sum { |w| w.count("_") }
  end

  char_count = Benchmark.measure do
    words.sum { |w| w.count('_') }
  end

  ratio = char_count.real > 0 ? (string_count.real / char_count.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  count(\"_\")=#{string_count.real.round(6).to_s.ljust(9)}s  count('_')=#{char_count.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

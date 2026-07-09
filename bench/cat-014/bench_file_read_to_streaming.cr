require "benchmark"

puts "=== File.read vs File.open streaming ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  content = "hello world\n" * n
  filename = "/tmp/cat014_bench_#{n}.txt"
  File.write(filename, content)

  file_read = Benchmark.measure do
    data = File.read(filename)
    data.lines.size
  end

  file_each_line = Benchmark.measure do
    count = 0
    File.open(filename) { |f| f.each_line { count += 1 } }
    count
  end

  ratio = file_read.real > 0 ? (file_read.real / file_each_line.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  File.read=#{file_read.real.round(6).to_s.ljust(9)}s  File.each_line=#{file_each_line.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"

  File.delete(filename)
end

puts ""
puts "=== File.read_lines vs File.open each_line ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  content = "hello world\n" * n
  filename = "/tmp/cat014_lines_bench_#{n}.txt"
  File.write(filename, content)

  read_lines = Benchmark.measure do
    lines = File.read_lines(filename)
    lines.size
  end

  each_line = Benchmark.measure do
    count = 0
    File.open(filename) { |f| f.each_line { count += 1 } }
    count
  end

  ratio = read_lines.real > 0 ? (read_lines.real / each_line.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  File.read_lines=#{read_lines.real.round(6).to_s.ljust(9)}s  File.each_line=#{each_line.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"

  File.delete(filename)
end

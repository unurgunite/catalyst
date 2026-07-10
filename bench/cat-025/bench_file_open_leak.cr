require "benchmark"

puts "=== File.open vs File.open with block ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  path = "/tmp/bench_file_#{n}.txt"
  File.write(path, "hello")

  open_no_block = Benchmark.measure {
    n.times do
      f = File.open(path)
      f.gets
      f.close
    end
  }

  open_block = Benchmark.measure {
    n.times do
      File.open(path) { |f| f.gets }
    end
  }

  ratio = open_block.real > 0 ? (open_no_block.real / open_block.real).round(2) : Float64::INFINITY
  puts "n=#{n.to_s.ljust(6)}  no-block=#{open_no_block.real.round(6).to_s.ljust(9)}s  block=#{open_block.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

File.delete(path) if File.exists?(path)

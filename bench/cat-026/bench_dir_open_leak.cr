require "benchmark"

puts "=== Dir.open vs Dir.open with block ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  tmpdir = "/tmp/bench_dir_#{n}"
  Dir.mkdir_p(tmpdir)

  open_no_block = Benchmark.measure {
    n.times do
      d = Dir.open(tmpdir)
      d.entries
      d.close
    end
  }

  open_block = Benchmark.measure {
    n.times do
      Dir.open(tmpdir) { |d| d.entries }
    end
  }

  ratio = open_block.real > 0 ? (open_no_block.real / open_block.real).round(2) : Float64::INFINITY
  puts "n=#{n.to_s.ljust(6)}  no-block=#{open_no_block.real.round(6).to_s.ljust(9)}s  block=#{open_block.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

Dir.rmdir(tmpdir) if Dir.exists?(tmpdir)

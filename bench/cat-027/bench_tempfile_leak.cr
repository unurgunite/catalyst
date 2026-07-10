require "benchmark"

puts "=== Tempfile.new vs Tempfile.open block (microbenchmark) ==="
puts ""

[10, 100, 1_000].each do |n|
  open_no_block = Benchmark.measure {
    n.times do
      f = File.tempfile("bench")
      f.puts "hello"
      f.close
      File.delete(f.path)
    end
  }

  open_block = Benchmark.measure {
    n.times { File.tempfile("bench") { |f| f.puts "hello" } }
  }

  ratio = open_block.real > 0 ? (open_no_block.real / open_block.real).round(2) : Float64::INFINITY
  puts "n=#{n.to_s.ljust(6)}  manual=#{open_no_block.real.round(6).to_s.ljust(9)}s  block=#{open_block.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

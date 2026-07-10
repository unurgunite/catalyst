require "benchmark"
require "http"

puts "=== HTTP::Client.new without block vs with block ==="
puts ""
puts "Block form ensures close even on exceptions (safety, not speed)."
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  open_no_block = Benchmark.measure {
    n.times do
      c = HTTP::Client.new(URI.new("http", "localhost", 9999))
      c.close
    end
  }

  open_block = Benchmark.measure {
    n.times { HTTP::Client.new(URI.new("http", "localhost", 9999)) { |c| } }
  }

  ratio = open_block.real > 0 ? (open_no_block.real / open_block.real).round(2) : Float64::INFINITY
  puts "n=#{n.to_s.ljust(6)}  manual=#{open_no_block.real.round(6).to_s.ljust(9)}s  block=#{open_block.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

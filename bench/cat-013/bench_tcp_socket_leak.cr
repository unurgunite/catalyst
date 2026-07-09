# Benchmark: manual close vs block form resource pattern
#
# Measures overhead of ensuring resource cleanup via block form
# vs manual close (simulating TCPSocket-like usage).

require "benchmark"

# Resource simulating TCPSocket: requires explicit close
class TcpResource
  def initialize(@host : String, @port : Int32)
  end

  # Block form (safe) — auto-closes in ensure
  def self.open(host : String, port : Int32, &)
    resource = new(host, port)
    yield resource
  ensure
    resource.close if resource
  end

  def close
  end
end

puts "=== TCPSocket resource pattern: manual close vs block form ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  manual = Benchmark.measure do
    n.times do
      r = TcpResource.new("example.com", 80)
      r.close
    end
  end

  block_form = Benchmark.measure do
    n.times do
      TcpResource.open("example.com", 80) { |r| }
    end
  end

  ratio = block_form.real > 0 ? (manual.real / block_form.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  manual=#{manual.real.round(6).to_s.ljust(9)}s  block=#{block_form.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

require "benchmark"

def write_to_s(io : IO, obj)
  io << obj.to_s
end

def write_direct(io : IO, obj)
  io << obj
end

puts "=== puts obj.to_s vs puts obj (using IO#<<) ==="
puts ""

io = IO::Memory.new

[10, 100, 1_000, 10_000, 100_000].each do |n|
  obj = "hello"

  with_to_s = Benchmark.measure {
    n.times { write_to_s(io, obj) }
  }

  without = Benchmark.measure {
    n.times { write_direct(io, obj) }
  }

  ratio = without.real > 0 ? (with_to_s.real / without.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  to_s=#{with_to_s.real.round(8).to_s.ljust(11)}s  direct=#{without.real.round(8).to_s.ljust(11)}s  #{ratio}x faster"
end

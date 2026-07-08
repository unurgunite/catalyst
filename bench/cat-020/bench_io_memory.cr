require "benchmark"

puts "=== IO::Memory.new + write + .to_s vs String.build ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  data = "hello world "
  count = n

  io_mem = Benchmark.measure { io = IO::Memory.new; count.times { io << data }; io.to_s }
  str_build = Benchmark.measure { String.build { |sb| count.times { sb << data } } }
  ratio = str_build.real > 0 ? (io_mem.real / str_build.real).round(2) : Float64::INFINITY

  puts "n=#{count.to_s.ljust(6)}  IO::Memory=#{io_mem.real.round(6).to_s.ljust(9)}s  String.build=#{str_build.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

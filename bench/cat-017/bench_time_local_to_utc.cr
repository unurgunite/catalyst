require "benchmark"

puts "=== Time.local vs Time.utc ==="
puts ""

times = 1_000
puts "Creating Time #{times} times:"
puts ""

local = Benchmark.measure { times.times { Time.local(2024, 1, 1, 12, 30, 45) } }
utc = Benchmark.measure { times.times { Time.utc(2024, 1, 1, 12, 30, 45) } }
ratio = utc.real > 0 ? (local.real / utc.real).round(2) : Float64::INFINITY

puts "  Time.local(2024,1,1,12,30,45) x #{times} = #{local.real.round(6)}s"
puts "  Time.utc(2024,1,1,12,30,45) x #{times}    = #{utc.real.round(6)}s"
puts "  #{ratio}x faster"

puts ""
puts "Creating Time with date components:"
puts ""

local = Benchmark.measure { times.times { Time.local(2024, 1, 1) } }
utc = Benchmark.measure { times.times { Time.utc(2024, 1, 1) } }
ratio = utc.real > 0 ? (local.real / utc.real).round(2) : Float64::INFINITY

puts "  Time.local(2024, 1, 1) x #{times} = #{local.real.round(6)}s"
puts "  Time.utc(2024, 1, 1) x #{times}    = #{utc.real.round(6)}s"
puts "  #{ratio}x faster"

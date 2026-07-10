require "benchmark"

# Simulates disabled log level — block form skips interpolation entirely
module Logger
  @@enabled = false

  def self.debug(msg : String)
    msg if @@enabled
  end

  def self.debug(&)
    yield if @@enabled
  end
end

puts "=== Logging block form: interpolated string vs block (log disabled) ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  name = "world"

  interpolated = Benchmark.measure {
    n.times { Logger.debug("hello #{name}") }
  }

  blocked = Benchmark.measure {
    n.times { Logger.debug { "hello #{name}" } }
  }

  ratio = blocked.real > 0 ? (interpolated.real / blocked.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  interpolated=#{interpolated.real.round(8).to_s.ljust(11)}s  block=#{blocked.real.round(8).to_s.ljust(11)}s  #{ratio}x faster"
end

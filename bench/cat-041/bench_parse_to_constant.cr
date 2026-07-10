require "benchmark"
require "uri"

puts "=== URI.parse inside loop vs constant ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  url = "https://example.com"

  inside = Benchmark.measure {
    n.times { URI.parse(url) }
  }

  parsed = URI.parse(url)
  outside = Benchmark.measure {
    n.times { parsed }
  }

  ratio = outside.real > 0 ? (inside.real / outside.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  inside=#{inside.real.round(8).to_s.ljust(11)}s  constant=#{outside.real.round(8).to_s.ljust(11)}s  #{ratio}x faster"
end

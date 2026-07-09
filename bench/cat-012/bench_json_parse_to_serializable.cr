require "benchmark"
require "json"

puts "=== JSON.parse vs JSON::Serializable ==="
puts ""

# Minimal JSON::Serializable struct for benchmark
struct Point
  include JSON::Serializable
  property x : Int32
  property y : Int32
end

[10, 100, 1_000, 10_000, 100_000].each do |n|
  json = (1..n).map { |i| %({"x":#{i},"y":#{i * 2}}) }.join("\n")

  parse_as_h = Benchmark.measure do
    json.each_line do |line|
      h = JSON.parse(line).as_h
      h["x"].as_i64
    end
  end

  serializable = Benchmark.measure do
    json.each_line do |line|
      p = Point.from_json(line)
      p.x
    end
  end

  ratio = parse_as_h.real > 0 ? (serializable.real > 0 ? (parse_as_h.real / serializable.real).round(2) : Float64::INFINITY) : 0.0

  puts "n=#{n.to_s.ljust(6)}  parse+.as_h=#{parse_as_h.real.round(6).to_s.ljust(9)}s  from_json=#{serializable.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

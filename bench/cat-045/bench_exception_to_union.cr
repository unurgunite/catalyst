require "benchmark"

puts "=== raise/rescue vs Union(T, Nil) return ==="
puts ""

class LookupWithRaise
  def fetch(key : String) : String
    raise ArgumentError.new("missing #{key}") if key.empty?
    "value:#{key}"
  end
end

class LookupWithUnion
  def fetch(key : String) : String?
    return nil if key.empty?
    "value:#{key}"
  end
end

# Failure rate: share of lookups that miss.
[0.0, 0.01, 0.1, 0.5].each do |miss_rate|
  keys = (1..100_000).map { |i| i % (1 / [miss_rate, 0.0001].max).to_i == 0 ? "" : "k#{i}" }

  with_raise = LookupWithRaise.new
  raise_bench = Benchmark.measure do
    keys.each do |key|
      begin
        with_raise.fetch(key)
      rescue ArgumentError
      end
    end
  end

  with_union = LookupWithUnion.new
  union_bench = Benchmark.measure do
    keys.each do |key|
      with_union.fetch(key)
    end
  end

  ratio = union_bench.real > 0 ? (raise_bench.real / union_bench.real).round(2) : Float64::INFINITY

  puts "miss=#{miss_rate.to_s.ljust(4)}  raise/rescue=#{raise_bench.real.round(6).to_s.ljust(9)}s  union=#{union_bench.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

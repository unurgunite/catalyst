require "benchmark"

puts "=== Thread.new vs spawn ==="
puts ""

[10, 100, 1_000].each do |n|
  thread_new = Benchmark.measure do
    n.times do
      Thread.new { }
    end
  end

  spawn_it = Benchmark.measure do
    n.times do
      spawn { }
    end
  end

  ratio = spawn_it.real > 0 ? (thread_new.real / spawn_it.real).round(2) : Float64::INFINITY
  puts "n=#{n.to_s.ljust(6)}  Thread.new=#{thread_new.real.round(6).to_s.ljust(9)}s  spawn=#{spawn_it.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

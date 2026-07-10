require "benchmark"

puts "=== DB.open without block vs with block ==="
puts ""

[10, 100, 1_000, 10_000, 100_000].each do |n|
  open_no_block = Benchmark.measure {
    n.times do
      db = DB.open("sqlite3:///tmp/bench_db_#{n}.db")
      db.exec("SELECT 1")
      db.close
    end
  }

  open_block = Benchmark.measure {
    n.times do
      DB.open("sqlite3:///tmp/bench_db_#{n}.db") { |db| db.exec("SELECT 1") }
    end
  }

  ratio = open_block.real > 0 ? (open_no_block.real / open_block.real).round(2) : Float64::INFINITY
  puts "n=#{n.to_s.ljust(6)}  no-block=#{open_no_block.real.round(6).to_s.ljust(9)}s  block=#{open_block.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end

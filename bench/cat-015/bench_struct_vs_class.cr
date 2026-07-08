require "benchmark"

# Struct vs Class allocation & access benchmark
# Demonstrates why Struct is preferred for small data objects

puts "=== Struct vs Class: allocation and field access ==="
puts ""

struct PointStruct
  property x, y

  def initialize(@x : Int32, @y : Int32)
  end
end

class PointClass
  property x, y

  def initialize(@x : Int32, @y : Int32)
  end
end

n = 1_000_000

puts "Creating #{n} instances:"
puts ""

struct_time = Benchmark.measure do
  n.times { PointStruct.new(1, 2) }
end

class_time = Benchmark.measure do
  n.times { PointClass.new(1, 2) }
end

ratio = class_time.real > 0 ? (struct_time.real / class_time.real).round(3) : Float64::INFINITY

puts "  PointStruct.new(1, 2) x #{n} = #{struct_time.real.round(6)}s"
puts "  PointClass.new(1, 2) x #{n}   = #{class_time.real.round(6)}s"
puts "  struct/class ratio: #{ratio} (lower = struct faster)"
puts ""

puts "Field access (#{n} reads):"
puts ""

struct_read_time = Benchmark.measure do
  p = PointStruct.new(1, 2)
  n.times { p.x; p.y }
end

class_read_time = Benchmark.measure do
  p = PointClass.new(1, 2)
  n.times { p.x; p.y }
end

ratio_read = class_read_time.real > 0 ? (struct_read_time.real / class_read_time.real).round(3) : Float64::INFINITY

puts "  struct field read:   #{struct_read_time.real.round(6)}s"
puts "  class field read:    #{class_read_time.real.round(6)}s"
puts "  struct/class ratio:  #{ratio_read} (lower = struct faster)"

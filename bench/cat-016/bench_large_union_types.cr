require "benchmark"
require "../../src/catalyst"

code_large = "def foo : Int32 | String | Nil | Bool; 1; end"
code_small = "def foo : String; 1; end"

rule = Catalyst::Rules::LargeUnionTypes.new

puts "=== LargeUnionTypes rule benchmark ==="
puts

large_ips = 0.0
small_ips = 0.0

job = Benchmark.ips do |bm|
  bm.report("def with 4-type union") do
    ast = Crystal::Parser.new(code_large).parse
    context = Catalyst::Context.new("test.cr", code_large)
    visitor = Catalyst::Visitors::FileVisitor.new([rule] of Catalyst::Rule, context)
    ast.accept(visitor)
    visitor.results
  end

  bm.report("def with single type") do
    ast = Crystal::Parser.new(code_small).parse
    context = Catalyst::Context.new("test.cr", code_small)
    visitor = Catalyst::Visitors::FileVisitor.new([rule] of Catalyst::Rule, context)
    ast.accept(visitor)
    visitor.results
  end
end

# `Benchmark.ips` prints its own table but no machine-readable speedup, so the
# rule's cost is restated here in the format `bench/run_all.cr` summarises:
# how much more expensive a 4-type union signature is to analyse than a
# single-type one.
large_mean, small_mean = job.items.map(&.mean)
speedup = small_mean > 0 ? (small_mean / large_mean).round(2) : Float64::INFINITY

puts ""
puts "Analysing a 4-type union signature is #{speedup}x slower than a single type."

require "benchmark"
require "../src/catalyst"

code_large = "def foo : Int32 | String | Nil | Bool; 1; end"
code_small = "def foo : String; 1; end"

rule = Catalyst::Rules::LargeUnionTypes.new

puts "=== LargeUnionTypes rule benchmark ==="
puts

Benchmark.ips do |bm|
  bm.report("def with 4-type union") do
    ast = Catalyst::Parser.new(code_large).parse
    context = Catalyst::Context.new("test.cr", code_large)
    visitor = Catalyst::Visitors::FileVisitor.new([rule] of Catalyst::Rule, context)
    ast.accept(visitor)
    visitor.results
  end

  bm.report("def with single type") do
    ast = Catalyst::Parser.new(code_small).parse
    context = Catalyst::Context.new("test.cr", code_small)
    visitor = Catalyst::Visitors::FileVisitor.new([rule] of Catalyst::Rule, context)
    ast.accept(visitor)
    visitor.results
  end
end

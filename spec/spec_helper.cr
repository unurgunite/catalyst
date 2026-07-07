require "spec"
require "../src/catalyst"

def parse_code(code : String) : Crystal::ASTNode
  Crystal::Parser.new(code).parse
end

def run_rule(rule : Catalyst::Rule, code : String) : Array(Catalyst::Result)
  ast = parse_code(code)
  context = Catalyst::Context.new("test.cr", code)
  visitor = Catalyst::Visitors::FileVisitor.new([rule], context)
  ast.accept(visitor)
  visitor.results
end

def assert_finding(rule : Catalyst::Rule, code : String, expected_count : Int32 = 1)
  results = run_rule(rule, code)
  results.size.should eq(expected_count)
end

def assert_no_finding(rule : Catalyst::Rule, code : String)
  assert_finding(rule, code, 0)
end

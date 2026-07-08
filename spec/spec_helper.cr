require "spec"
require "../src/catalyst"

# # Parse Crystal source code into an AST node.
def parse_code(code : String) : Crystal::ASTNode
  Crystal::Parser.new(code).parse
end

# # Run a single rule against Crystal source code.
# # Returns all findings produced by the rule.
def run_rule(rule : Catalyst::Rule, code : String) : Array(Catalyst::Result)
  ast = parse_code(code)
  context = Catalyst::Context.new("test.cr", code)
  visitor = Catalyst::Visitors::FileVisitor.new([rule] of Catalyst::Rule, context)
  ast.accept(visitor)
  visitor.results
end

# # Assert a rule produces exactly `expected_count` findings for given code.
def assert_finding(rule : Catalyst::Rule, code : String, expected_count : Int32 = 1)
  results = run_rule(rule, code)
  results.size.should eq(expected_count)
end

# # Assert a rule produces no findings for given code.
def assert_no_finding(rule : Catalyst::Rule, code : String)
  assert_finding(rule, code, 0)
end

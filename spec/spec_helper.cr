require "spec"
require "../src/catalyst"
require "file_utils"

# # Parse Crystal source code into an AST node.
def parse_code(code : String) : Crystal::ASTNode
  Crystal::Parser.new(code).parse
end

# # Run a single rule against Crystal source code.
# # Returns all findings produced by the rule.
def run_rule(rule : Catalyst::Rule, code : String) : Array(Catalyst::Result)
  ast = parse_code(code)
  context = Catalyst::Context.new("test.cr", code)
  rule.setup("test.cr", code)
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

# --- Filesystem and config helpers for the CLI and runner specs ---
def temp_dir(&)
  dir = File.join(Dir.tempdir, "catalyst_spec_#{Random.rand(1_000_000_000)}")
  Dir.mkdir_p(dir)
  begin
    yield dir
  ensure
    FileUtils.rm_rf(dir)
  end
end

def write(dir : String, name : String, content : String) : String
  path = File.join(dir, name)
  File.write(path, content)
  path
end

# Exercise a rule's public fix output; the masking helper stays protected.
def fix_for(rule : Catalyst::Rule, code : String) : String?
  run_rule(rule, code).first?.try(&.fix_replacement)
end

def full_config(rules_yaml : String = "") : Catalyst::Config
  Catalyst::Config.from_yaml("severity: warning\nformat: terminal\nrules:\n#{rules_yaml}ignore: []\npaths: []\n")
end

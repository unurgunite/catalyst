# Applies `catalyst --fix` to each fixable rule and checks the result still
# compiles.
#
# The spec suite checks that a fix is *emitted*, not that the emitted code
# builds. A rewrite that turns `Regex.new("x")` into an undefined `X` parses
require "file_utils"

# fine and fails only at compile time, so this is the gate for that class of
# bug. Run from the repo root: crystal run scripts/check_fix_compiles.cr -- --run
#
# The snippets are asserted against the real rule list in
# spec/fix_compiles_spec.cr, so a fixable rule without a snippet fails there.

module Catalyst
  FIX_COMPILE_CASES = {
    "CAT-001" => "x = [3, 1].sort.first",
    "CAT-002" => "total = [1, 2].map { |n| n * 2 }.sum",
    "CAT-006" => "h = {\"a\" => 1}\nh.keys.each { |key| puts key }",
    "CAT-007" => "list = [1, 2]\nlist.reverse.each { |n| puts n }",
    "CAT-008" => "found = [1, 2].select { |n| n > 1 }.first",
    "CAT-018" => "s = \"abc\"\nif s.match(/re/)\nend",
    "CAT-039" => "class Foo\n  Regex.new(\"ab\")\nend",
  }
end

def sh(cmd : String) : Bool
  Process.run(cmd, shell: true, output: Process::Redirect::Close, error: Process::Redirect::Close).success?
end

# Runs only when executed directly. `crystal spec` requires this file for the
# snippet table and `crystal run` caches binaries under a generic temp name,
# so PROGRAM_NAME cannot tell the two apart — the marker argument can.
if ARGV.includes?("--run")
  dir = File.join(Dir.tempdir, "catalyst_fix_compile_#{Random.rand(1_000_000_000)}")
  Dir.mkdir_p(dir)
  failures = [] of String

  Catalyst::FIX_COMPILE_CASES.each do |id, code|
    file = File.join(dir, "#{id}.cr")
    File.write(file, code + "\n")

    unless sh("./bin/catalyst --fix --severity hint #{file}")
      failures << "#{id}: --fix exited non-zero"
      next
    end

    fixed = File.read(file)
    failures << "#{id}: fixed source does not compile:\n#{fixed}" unless sh("crystal build --no-codegen #{file}")
  end

  FileUtils.rm_rf(dir)

  if failures.empty?
    puts "check_fix_compiles: #{Catalyst::FIX_COMPILE_CASES.size} fixed files compile"
  else
    failures.each { |item| STDERR.puts "FAIL #{item}" }
    STDERR.puts "\n#{failures.size} failure(s)"
    exit 1
  end
end

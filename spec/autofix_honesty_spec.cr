require "./spec_helper"

# Every rule advertising `auto_fixable?` must emit at least one
# `fix_replacement` on a representative positive case — otherwise `--fix`
# silently does nothing while `--list-rules` claims the rule is fixable.
POSITIVE_CASES = {
  "CAT-001" => "x.sort.first",
  "CAT-002" => "[1, 2].map { |x| x * 2 }.sum",
  "CAT-003" => "a.select { |x| x }.reject { |x| !x }",
  "CAT-004" => "items.each { |i| [1, 2, 3].includes?(i) }",
  "CAT-005" => "ary.unshift(1)",
  "CAT-006" => "h.keys.each { |k| puts k }",
  "CAT-007" => "ary.reverse.each { |x| puts x }",
  "CAT-008" => "[1, 2, 3].select { |x| x.even? }.first",
  "CAT-009" => "[1, 2].group_by { |x| x }.map { |k, v| v.size }",
  "CAT-010" => "items.each { |i| s += i }",
  "CAT-011" => %q(s.gsub("a", "b").gsub("c", "d")),
  "CAT-012" => %q(JSON.parse(File.read("d.json"))["k"]),
  "CAT-013" => %q(TCPSocket.new("h", 80)),
  "CAT-014" => %q(File.read("data.bin")),
  "CAT-015" => "class Point\n  getter x : Int32\nend",
  "CAT-016" => "def f : Int32 | String | Bool | Float64\nend",
  "CAT-017" => "Time.local(2024, 1, 1)",
  "CAT-018" => "if s.match(/re/)\nend",
  "CAT-019" => %q(Regex.new("pattern")),
  "CAT-020" => "IO::Memory.new.to_s",
  "CAT-021" => "h.values.each { |v| puts v }",
  "CAT-022" => "[1, 2, 3].shuffle.first",
  "CAT-023" => %q(names.includes?("a")),
  "CAT-024" => "h.keys.map { |k| k }",
  "CAT-025" => %q(File.open("f.txt")),
  "CAT-026" => %q(Dir.open(".")),
  "CAT-027" => %q(Tempfile.new("t")),
  "CAT-028" => %q(HTTP::Client.get("http://x")),
  "CAT-029" => %q(DB.open("sqlite3://x")),
  "CAT-030" => "h.keys.includes?(k)",
  "CAT-031" => "h.values.includes?(v)",
  "CAT-032" => %q(s.split(",").first),
  "CAT-033" => "[1, 2].select { |x| x }.map { |x| x }",
  "CAT-034" => "[1, 2].each_with_index.map { |x, i| x }",
  "CAT-035" => %q(s.split("")),
  "CAT-036" => "s.chars.each { |c| puts c }",
  "CAT-037" => %q(log.info("x=#{x}")),
  "CAT-038" => "Array(Int32).new",
  "CAT-039" => "def f\n  Regex.new(\"x\")\nend",
  "CAT-040" => %q("a" + "b" + "c"),
  "CAT-041" => %q(URI.parse("https://example.com")),
  "CAT-042" => "sleep(0)",
  "CAT-043" => "Random.new.rand",
  "CAT-044" => "x ** 2",
  "CAT-045" => "def f\n  raise \"x\"\nend",
  "CAT-046" => "[1, 2].reverse.reverse",
  "CAT-047" => %q(s.upcase.downcase),
  "CAT-048" => %q(puts x.to_s),
  "CAT-049" => "Thread.new { work }",
  "CAT-050" => "Fiber.new { work }.resume",
}

describe "auto_fixable? honesty" do
  it "every fixable rule emits fix_replacement on its positive case" do
    Catalyst::Rule.all.each do |rule|
      next unless rule.auto_fixable?
      code = POSITIVE_CASES[rule.id]?
      code.should_not be_nil, "no positive case registered for #{rule.id}"
      next unless code
      results = run_rule(rule, code)
      results.should_not be_empty, "#{rule.id} fires nothing on its positive case"
      results.any?(&.fix_replacement).should be_true,
        "#{rule.id} claims auto_fixable? but emits no fix_replacement"
    end
  end
end

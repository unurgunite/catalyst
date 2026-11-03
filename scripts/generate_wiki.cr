require "../src/catalyst"

# Generates the GitHub wiki from the live rule set.
# Usage: WIKI_OUT=<wiki-checkout-dir> crystal run scripts/generate_wiki.cr
#
# Rule metadata comes from the rules themselves, so a new rule or a changed
# severity cannot drift out of the wiki. Prose and code samples are not in the
# AST, so they live in CATALOG below — add an entry when adding a rule, or the
# generator fails loudly rather than publishing a page without examples.

alias Entry = NamedTuple(
  category: String,
  title: String,
  problem: String,
  bad: String,
  good: String?)

CATALOG = {
  "CAT-001" => {category: "Array & Enumerable", title: "sort.first -> min/max",
                problem: "`sort` is O(n log n); `min`/`max` scan once in O(n). The intermediate array is also allocated for nothing.",
                bad: "ary.sort.first\nary.sort.last", good: "ary.min\nary.max"},
  "CAT-002" => {category: "Array & Enumerable", title: "map{}.sum -> sum{}",
                problem: "`map` allocates a whole intermediate array whose only reader is `sum`. `sum` with a block accumulates directly.",
                bad: "prices.map { |p| p * 1.1 }.sum", good: "prices.sum { |p| p * 1.1 }"},
  "CAT-003" => {category: "Array & Enumerable", title: "select + reject -> partition",
                problem: "Two passes over the same collection, each allocating an array. `partition` splits once.",
                bad: "passing = users.select { |u| u.active }\nidle    = users.reject { |u| u.active }",
                good: "passing, idle = users.partition { |u| u.active }"},
  "CAT-004" => {category: "Array & Enumerable", title: "Array#include? -> Set",
                problem: "`Array#includes?` is O(n) per call. Inside a loop that is O(n*m); a `Set` makes each lookup O(1).",
                bad: "words.each do |w|\n  next unless allowed.includes?(w)\nend",
                good: "allowed_set = allowed.to_set\nwords.each do |w|\n  next unless allowed_set.includes?(w)\nend"},
  "CAT-005" => {category: "Array & Enumerable", title: "shift/unshift -> Deque",
                problem: "`Array#shift` and `#unshift` move every remaining element, so a queue built on `Array` degrades to O(n) per operation.",
                bad: "queue = [1, 2, 3]\nqueue.shift", good: "queue = Deque{1, 2, 3}\nqueue.shift"},
  "CAT-006" => {category: "Hash", title: "hash.keys.each -> each_key",
                problem: "`keys` allocates an array of every key just to iterate it. `each_key` iterates in place.",
                bad: "config.keys.each { |k| puts k }", good: "config.each_key { |k| puts k }"},
  "CAT-007" => {category: "Array & Enumerable", title: "reverse.each -> reverse_each",
                problem: "`reverse` allocates a reversed copy. `reverse_each` walks backwards without one.",
                bad: "items.reverse.each { |i| puts i }", good: "items.reverse_each { |i| puts i }"},
  "CAT-008" => {category: "Array & Enumerable", title: "select.first/last -> find",
                problem: "`select` builds an array of every match and then throws all but the first away. `find` stops at the first hit.",
                bad: "users.select { |u| u.admin? }.first\nusers.select { |u| u.admin? }.first?",
                good: "users.find! { |u| u.admin? }\nusers.find { |u| u.admin? }"},
  "CAT-009" => {category: "Hash", title: "group_by -> counter hash",
                problem: "`group_by` allocates an array per key just to call `size` on it. A counter hash only keeps the counts.",
                bad: "counts = words.group_by(&.itself).transform_values(&.size)",
                good: "counts = Hash(String, Int32).new(0)\nwords.each { |w| counts[w] += 1 }"},
  "CAT-010" => {category: "String", title: "String#+ in loop -> String.build",
                problem: "Crystal strings are immutable, so every `+` allocates a new buffer and copies both sides. In a loop that is quadratic.",
                bad: "out = \"\"\nitems.each { |i| out += i.to_s }",
                good: "out = String.build { |io| items.each { |i| io << i } }"},
  "CAT-012" => {category: "Type & Serialization", title: "JSON.parse -> Serializable",
                problem: "Parsing into `JSON::Any` loses type safety and pays a hash lookup per field access. `JSON::Serializable` compiles the mapping.",
                bad: "data = JSON.parse(response.body)\nname = data[\"name\"].as_s",
                good: "class User\n  include JSON::Serializable\n  getter name : String\nend\nuser = User.from_json(response.body)"},
  "CAT-013" => {category: "Resource & IO", title: "TCPSocket leak",
                problem: "A socket opened without the block form is only closed if every path remembers to call `close`. One early return and the descriptor leaks.",
                bad: "socket = TCPSocket.new(host, 80)\nsocket << request\nsocket.close",
                good: "TCPSocket.open(host, 80) do |socket|\n  socket << request\nend"},
  "CAT-014" => {category: "Resource & IO", title: "File.read -> streaming",
                problem: "`File.read` loads the entire file into memory. Streaming keeps only a buffer — but for a config or fixture, reading whole is the right call.",
                bad: "File.read(path).each_line { |l| puts l }",
                good: "File.each_line(path) { |l| puts l }"},
  "CAT-015" => {category: "Type & Serialization", title: "Struct vs Class",
                problem: "A class whose fields are only read costs a heap allocation and a pointer chase on every access. A `Struct` is stack-allocated and copied by value.",
                bad: "class Point\n  getter x, y\n  def initialize(@x : Int32, @y : Int32)\n  end\nend",
                good: "struct Point\n  getter x, y\n  def initialize(@x : Int32, @y : Int32)\n  end\nend"},
  "CAT-016" => {category: "Type & Serialization", title: "Large union types",
                problem: "Every member of a union widens the type tag, the dispatch cost and the code Crystal generates for each call site.",
                bad: "alias Value = Int32 | String | Bool | Array(String)",
                good: "alias Value = Int32 | String"},
  "CAT-017" => {category: "Performance & Idiom", title: "Time.local -> Time.utc",
                problem: "`Time.local` reads the process TZ and does a conversion every call. When the timezone is irrelevant, UTC is a pure computation.",
                bad: "created_at = Time.local", good: "created_at = Time.utc"},
  "CAT-018" => {category: "String", title: "match -> matches?",
                problem: "`match` builds a `Regex::MatchData` object on every call, then the boolean context discards it. `matches?` skips the allocation.",
                bad: "if email.match(/@/)\n  # ...\nend", good: "if email.matches?(/@/)\n  # ...\nend"},
  "CAT-020" => {category: "Resource & IO", title: "IO::Memory -> String.build",
                problem: "`IO::Memory` allocates a growable buffer object around the same work `String.build` does directly.",
                bad: "io = IO::Memory.new\nio << \"a\" << \"b\"\nio.to_s", good: "String.build { |io| io << \"a\" << \"b\" }"},
  "CAT-021" => {category: "Hash", title: "values.each -> each_value",
                problem: "`values` allocates an array of every value just to iterate it. `each_value` iterates in place.",
                bad: "config.values.each { |v| puts v }", good: "config.each_value { |v| puts v }"},
  "CAT-022" => {category: "Array & Enumerable", title: "shuffle.first -> sample",
                problem: "`shuffle` permutes the entire collection to keep one element. `sample` picks without the reshuffle.",
                bad: "deck.shuffle.first", good: "deck.sample"},
  "CAT-023" => {category: "String", title: "includes? -> char comparison",
                problem: "A single-character `String` receiver allocates for a comparison a `Char` makes directly.",
                bad: "text.includes?(\"a\")", good: "text.includes?('a')"},
  "CAT-025" => {category: "Resource & IO", title: "File.open leak",
                problem: "A handle opened without a block is only closed if every path remembers to call `close`.",
                bad: "file = File.open(path)\nfile.gets\nfile.close",
                good: "File.open(path) do |file|\n  file.gets\nend"},
  "CAT-026" => {category: "Resource & IO", title: "Dir.open leak",
                problem: "A directory handle opened without a block is only closed if every path remembers to call `close`.",
                bad: "dir = Dir.open(path)\ndir.each { |e| puts e }\ndir.close",
                good: "Dir.open(path) do |dir|\n  dir.each { |e| puts e }\nend"},
  "CAT-027" => {category: "Resource & IO", title: "Tempfile leak",
                problem: "A tempfile left unclosed keeps its descriptor and its file alive until GC reaches it.",
                bad: "tmp = Tempfile.new(\"work\")\ntmp.print(data)", good: "Tempfile.open(\"work\") do |tmp|\n  tmp.print(data)\nend"},
  "CAT-028" => {category: "Resource & IO", title: "HTTP::Client leak",
                problem: "An `HTTP::Client` holds a socket. Constructed without a block, it survives until GC and can exhaust the connection pool.",
                bad: "client = HTTP::Client.new(uri)\nclient.get(\"/path\")\nclient.close",
                good: "HTTP::Client.get(uri)"},
  "CAT-029" => {category: "Resource & IO", title: "DB.open leak",
                problem: "A connection opened without the block form stays in the pool until GC runs, which under load means exhaustion.",
                bad: "db = DB.open(url)\ndb.exec(sql)", good: "DB.open(url) do |db|\n  db.exec(sql)\nend"},
  "CAT-030" => {category: "Hash", title: "keys.includes? -> has_key?",
                problem: "`keys` allocates an array of every key to search it. `has_key?` checks the hash directly.",
                bad: "if config.keys.includes?(\"mode\")", good: "if config.has_key?(\"mode\")"},
  "CAT-031" => {category: "Hash", title: "values.includes? -> has_value?",
                problem: "`values` allocates an array of every value to search it. `has_value?` walks the hash directly.",
                bad: "if config.values.includes?(\"debug\")", good: "if config.has_value?(\"debug\")"},
  "CAT-032" => {category: "String", title: "split.first -> split_limit",
                problem: "`split` builds an array of every field when only the first is used. A limit stops splitting at the second.",
                bad: "name = header.split(':').first", good: "name = header.split(':', 2).first"},
  "CAT-033" => {category: "Array & Enumerable", title: "select.map -> single-pass",
                problem: "`select` allocates an intermediate array that `map` immediately consumes. `compact_map` filters and transforms in one pass.",
                bad: "users.select { |u| u.admin? }.map { |u| u.name }",
                good: "users.compact_map { |u| u.name if u.admin? }"},
  "CAT-034" => {category: "Array & Enumerable", title: "each_with_index.map -> map_with_index",
                problem: "`each_with_index` allocates a tuple per element that `map` then unwraps. `map_with_index` passes the index directly.",
                bad: %q(items.each_with_index.map { |item, i| "#{i}: #{item}" }),
                good: %q(items.map_with_index { |item, i| "#{i}: #{item}" })},
  "CAT-035" => {category: "String", title: "split(\"\") -> each_char",
                problem: "`split(\"\")` allocates an array of one-character strings. `each_char` yields chars without the array.",
                bad: "text.split(\"\").each { |c| puts c }", good: "text.each_char { |c| puts c }"},
  "CAT-037" => {category: "Performance & Idiom", title: "Logging block form",
                problem: "A string built as a logging argument is built even when the message is filtered out. The block form defers construction.",
                bad: %q(Log.debug { "user=#{user.inspect}" }), good: %q(Log.debug { "user=#{user.inspect}" })},
  "CAT-038" => {category: "Performance & Idiom", title: "Capacity hints", problem: "Pre-sizing a collection avoids the geometric growth reallocations when the final size is known.",
                bad: "list = [] of Int32", good: "list = Array(Int32).new(capacity: 1000)"},
  "CAT-039" => {category: "String", title: "Regex.new in method -> constant",
                problem: "A `Regex` built inside a method is compiled on every call. A constant compiles once.",
                bad: "def parse(str)\n  Regex.new(\"^\\\\d+$\").match(str)\nend",
                good: "DIGITS = Regex.new(\"^\\\\d+$\")\n\ndef parse(str)\n  DIGITS.match(str)\nend"},
  "CAT-041" => {category: "Performance & Idiom", title: "Parse -> constant",
                problem: "`URI.parse` and `Time.parse` allocate and validate on every call. Inside a loop over a fixed format the work repeats needlessly.",
                bad: "urls.each { |u| URI.parse(\"https://example.com\") }",
                good: "BASE_URL = URI.parse(\"https://example.com\")\nurls.each { |_| BASE_URL }"},
  "CAT-042" => {category: "Performance & Idiom", title: "sleep(0) -> Fiber.yield",
                problem: "`sleep(0)` goes through the event loop's timer machinery to yield; `Fiber.yield` hands the scheduler control directly.",
                bad: "sleep(0)", good: "Fiber.yield"},
  "CAT-043" => {category: "Performance & Idiom", title: "Random.new reuse",
                problem: "`Random.new` seeds a fresh generator per call, which costs entropy and produces correlated sequences.",
                bad: "value = Random.new.rand(100)", good: "RNG = Random.new\nvalue = RNG.rand(100)"},
  "CAT-045" => {category: "Error handling", title: "raise -> Union return",
                problem: "Raising for an expected outcome makes callers pay exception setup and unwinding. A union return makes the case explicit and cheap.",
                bad: "def find_user(id) : User\n  user = lookup(id)\n  raise \"not found\" unless user\n  user\nend",
                good: "def find_user(id) : User?\n  lookup(id)\nend"},
  "CAT-049" => {category: "Concurrency", title: "Thread.new -> spawn",
                problem: "`Thread.new` starts an OS thread (~8MB of stack and a context switch per switch). A fiber is far cheaper — but only if a thread is not genuinely needed.",
                bad: "Thread.new { work }", good: "spawn { work }"},
  "CAT-050" => {category: "Concurrency", title: "Fiber.new -> spawn",
                problem: "`Fiber.new { }.resume` builds and immediately runs a fiber by hand. `spawn` enqueues it, which is the same for a fresh fiber and gives the scheduler a chance to order work.",
                bad: "Fiber.new { work }.resume", good: "spawn { work }"},
  "CAT-051" => {category: "Concurrency", title: "Fiber fan-out bound",
                problem: "`N.times { spawn }` starts N fibers at once. Above a few thousand the scheduler thrashes and each worker's stack adds up; a semaphore bounds it.",
                bad: "100_000.times { spawn { work } }",
                good: "permits = Channel(Nil).new(8)\n100_000.times do\n  permits.send(nil)\n  spawn { work; permits.receive }\nend"},
  "CAT-052" => {category: "Concurrency", title: "Blocking calls in spawn",
                problem: "A blocking call on the event-loop thread stops every other fiber, not just the caller. Such a call needs a timeout.",
                bad: "spawn { Process.run(\"curl\", [\"http://example.com\"]) }",
                good: "spawn { Process.run(\"curl\", [\"--max-time\", \"5\", \"http://example.com\"]) }"},
} of String => Entry

CATEGORY_ORDER = ["Array & Enumerable", "Hash", "String", "Resource & IO",
                  "Type & Serialization", "Error handling", "Performance & Idiom", "Concurrency"]

RULES = Catalyst::Rule.all.sort_by(&.id)

def check_catalog : Nil
  missing = RULES.reject { |rule| CATALOG.has_key?(rule.id) }
  extra = CATALOG.keys.reject { |id| RULES.any? { |rule| rule.id == id } }
  return if missing.empty? && extra.empty?

  raise "wiki catalog out of sync: missing #{missing.map(&.id)}, stale #{extra}"
end

def fix_mark(rule : Catalyst::Rule) : String
  rule.auto_fixable? ? "yes" : "no"
end

def severity_cell(rule : Catalyst::Rule) : String
  rule.enabled_by_default? ? rule.severity : "#{rule.severity} (opt-in)"
end

def notice(rule : Catalyst::Rule) : Array(String)
  return [] of String if rule.enabled_by_default? && !rule.auto_fixable?

  lines = [] of String
  unless rule.enabled_by_default?
    lines.concat(["> [!WARNING]",
                  "> This rule is **off by default**. Enable it with `catalyst --rules #{rule.id}`",
                  "> or `rules: {#{rule.id}: {enabled: true}}` in `.catalyst.yml`.",
                  ""])
  end
  if rule.auto_fixable?
    lines.concat(["> [!TIP]",
                  "> This rule supports auto-fix via `catalyst --fix`. Preview first with `--fix --dry-run`.",
                  ""])
  end
  lines
end

def code_sample(heading : String, code : String?) : Array(String)
  return [] of String unless code

  ["### #{heading}", "", "```crystal", code, "```", ""]
end

def page(rule : Catalyst::Rule, entry : Entry) : String
  lines = [] of String
  lines << "# #{rule.id} — #{entry[:title]}"
  lines << ""
  lines << "> **Severity:** `#{rule.severity}` | **Auto-fix:** #{rule.auto_fixable? ? "yes" : "no"}"
  lines << ""
  lines.concat(notice(rule))
  lines.concat(["## Description", "", rule.description, "", entry[:problem], ""])
  lines.concat(code_sample("Bad code", entry[:bad]))
  lines.concat(code_sample("Good code", entry[:good]))
  bench = "bench/cat-#{rule.id.lchop("CAT-")}/"
  lines.concat(["## Benchmark", "", "> [!NOTE]",
                "> See [`#{bench}`](https://github.com/unurgunite/catalyst/tree/master/#{bench})", ""])
  lines.join("\n")
end

def rule_table(category : String, rules : Array(Catalyst::Rule)) : Array(String)
  lines = [] of String
  plural = rules.size == 1 ? "rule" : "rules"
  lines.concat(["<details>", "<summary><b>#{category}</b> (#{rules.size} #{plural})</summary>", "",
                "| ID | Rule | Severity | Auto-fix |", "|---|---|---|---|"])
  rules.each do |rule|
    entry = CATALOG[rule.id]
    lines << "| #{rule.id} | [#{entry[:title]}](#{rule.id}) | #{severity_cell(rule)} | #{fix_mark(rule)} |"
  end
  lines.concat(["</details>", ""])
end

def home_header : Array(String)
  lines = [] of String
  lines.concat(["# Catalyst Rules", "",
                "Static performance analysis for **Crystal**. Detect allocation anti-patterns,",
                "algorithmic complexity issues, and resource leaks before they reach production.",
                "", "## Quick links", "",
                "- [Installation](https://github.com/unurgunite/catalyst#installation)",
                "- [Usage](https://github.com/unurgunite/catalyst#usage)",
                "- [`catalyst --list-rules`](https://github.com/unurgunite/catalyst#usage)",
                "", "## Rules", "",
                "**#{RULES.size} rules.** Numbers are not contiguous: CAT-019, 024, 036, 040, 044, 046,",
                "047 and 048 were removed, and their numbers stay retired so an old `ignore` entry",
                "still means what it did.", ""])
  unless RULES.all?(&.enabled_by_default?)
    lines.concat(["`opt-in` marks a rule that is off by default. Enable one for a single run with",
                  "`--rules <ID>`, or permanently with `rules: {<ID>: {enabled: true}}`.", ""])
  end
  lines
end

def home : String
  by_category = RULES.group_by { |rule| CATALOG[rule.id][:category] }
  lines = home_header
  CATEGORY_ORDER.each do |category|
    rules = by_category[category]? || [] of Catalyst::Rule
    lines.concat(rule_table(category, rules)) unless rules.empty?
  end
  lines.concat(["---", "",
                "**#{RULES.size} rules** | [`catalyst --list-rules`](https://github.com/unurgunite/catalyst#usage)"])
  lines.join("\n") + "\n"
end

# Crystal runs the CLI when catalyst.cr is required, even from here, so the
# entry condition is an env var rather than an argument.
if ENV["WIKI_OUT"]?.presence
  check_catalog
  dir = ENV["WIKI_OUT"]
  Dir.glob(File.join(dir, "CAT-*.md")).each { |stale| File.delete(stale) }
  RULES.each do |rule|
    File.write(File.join(dir, "#{rule.id}.md"), page(rule, CATALOG[rule.id]))
  end
  File.write(File.join(dir, "Home.md"), home)
  puts "wrote #{RULES.size} rule pages + Home.md to #{dir}"
end

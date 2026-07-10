require "benchmark"
require "json"

puts "=== Catalyst Benchmarks ==="
puts ""

dirs = Dir["bench/cat-*/"].sort

category_map = {
  "cat-001" => "array", "cat-002" => "array", "cat-003" => "array",
  "cat-004" => "array", "cat-005" => "array", "cat-007" => "array",
  "cat-008" => "array", "cat-022" => "array", "cat-033" => "array",
  "cat-034" => "array", "cat-046" => "array", "cat-047" => "array",
  "cat-048" => "array",
  "cat-006" => "hash", "cat-009" => "hash", "cat-021" => "hash",
  "cat-024" => "hash", "cat-030" => "hash", "cat-031" => "hash",
  "cat-010" => "string", "cat-011" => "string", "cat-018" => "string",
  "cat-019" => "string", "cat-023" => "string", "cat-032" => "string",
  "cat-035" => "string", "cat-036" => "string", "cat-039" => "string",
  "cat-040" => "string", "cat-041" => "string",
  "cat-020" => "io",
  "cat-013" => "resource", "cat-014" => "resource", "cat-025" => "resource",
  "cat-026" => "resource", "cat-027" => "resource", "cat-028" => "resource",
  "cat-029" => "resource",
  "cat-015" => "type", "cat-016" => "type",
  "cat-017" => "time",
  "cat-012" => "serialization",
  "cat-037" => "logging", "cat-038" => "performance",
  "cat-042" => "concurrency", "cat-043" => "random",
  "cat-044" => "math", "cat-049" => "concurrency",
  "cat-050" => "concurrency",
}

results = [] of NamedTuple(
  rule: String,
  description: String,
  best_ratio: Float64,
  category: String,
)

dirs.each do |dir|
  rule = File.basename(dir)
  bench_files = Dir["#{dir}bench_*.cr"].sort

  next if bench_files.empty?

  category = category_map[rule]? || "other"

  bench_files.each do |bench_file|
    description = bench_file.sub(/.*bench_/, "").sub(/\.cr$/, "").gsub('_', ' ')

    puts "--- Running #{rule}/#{File.basename(bench_file)} ---"
    puts ""

    output = IO::Memory.new
    status = Process.run(
      "crystal", ["run", bench_file],
      output: output,
      error: STDERR,
    )

    output_text = output.to_s
    puts output_text

    ratios = [] of Float64
    output_text.each_line do |line|
      if line =~ /(\d+\.\d+)x faster/
        ratios << $1.to_f
      end
    end

    best_ratio = ratios.max? || 0.0

    results << {
      rule: rule,
      description: description,
      best_ratio: best_ratio,
      category: category,
    }
  end
end

category_order = ["array", "hash", "string", "io", "resource", "type", "time", "serialization", "logging", "performance", "concurrency", "random", "math", "other"]

sorted_results = results.sort do |a, b|
  cat_cmp = (category_order.index(a[:category]) || 99) <=> (category_order.index(b[:category]) || 99)
  if cat_cmp == 0
    b[:best_ratio] <=> a[:best_ratio]
  else
    cat_cmp
  end
end

puts ""
puts "============================================"
puts "  Summary"
puts "============================================"
puts "  #{sprintf("%-12s", "Category")}  #{sprintf("%-8s", "Rule")}  #{sprintf("%-30s", "Description")}  #{sprintf("%-10s", "Best Ratio")}  Verdict"
puts "  #{"-" * 80}"

sorted_results.each do |r|
  verdict = if r[:best_ratio] >= 5.0
              "significant"
            elsif r[:best_ratio] >= 2.0
              "moderate"
            else
              "negligible"
            end

  puts "  #{sprintf("%-12s", r[:category])}  #{sprintf("%-8s", r[:rule])}  #{sprintf("%-30s", r[:description])}  #{sprintf("%-10.2f", r[:best_ratio])}  #{verdict}"
end

puts ""
exit 0

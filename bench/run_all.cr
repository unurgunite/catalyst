require "benchmark"
require "json"

puts "=== Catalyst Benchmarks ==="
puts ""

dirs = Dir["bench/cat-*/"].sort

category_map = {
  "cat-001" => "array", "cat-002" => "array", "cat-003" => "array",
  "cat-004" => "array", "cat-005" => "array", "cat-007" => "array",
  "cat-008" => "array", "cat-022" => "array", "cat-033" => "array",
  "cat-034" => "array",
  "cat-006" => "hash", "cat-009" => "hash", "cat-021" => "hash",
  "cat-030" => "hash", "cat-031" => "hash",
  "cat-010" => "string", "cat-011" => "string", "cat-018" => "string",
  "cat-023" => "string", "cat-032" => "string",
  "cat-035" => "string", "cat-039" => "string", "cat-041" => "string",
  "cat-020" => "io",
  "cat-013" => "resource", "cat-014" => "resource", "cat-025" => "resource",
  "cat-026" => "resource", "cat-027" => "resource", "cat-028" => "resource",
  "cat-029" => "resource",
  "cat-015" => "type", "cat-016" => "type",
  "cat-017" => "time",
  "cat-012" => "serialization",
  "cat-037" => "logging", "cat-038" => "performance",
  "cat-042" => "concurrency", "cat-043" => "random",
  "cat-045" => "error-handling",
  "cat-049" => "concurrency",
  "cat-050" => "concurrency",
  "cat-051" => "concurrency",
  "cat-052" => "concurrency",
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
      # Each benchmark states the speedup of the recommended form over the
      # form the rule flags, as "Nx faster". A line saying "Nx slower" means
      # the flagged form wins, i.e. a speedup of 1/N. Benchmarks that make no
      # speed claim (safety rules, detection cost) print neither and are
      # reported as n/a instead of a misleading 0.
      if line =~ /(\d+(?:\.\d+)?)x faster/
        ratios << $1.to_f
      elsif line =~ /(\d+(?:\.\d+)?)x slower/
        speedup = $1.to_f
        ratios << (speedup > 0 ? 1.0 / speedup : 0.0)
      end
    end

    best_ratio = ratios.max? || Float64::NAN

    results << {
      rule:        rule,
      description: description,
      best_ratio:  best_ratio,
      category:    category,
    }
  end
end

category_order = ["array", "hash", "string", "io", "resource", "type", "time", "serialization", "logging", "performance", "concurrency", "random", "math", "error-handling", "other"]

sorted_results = results.sort do |a, b|
  cat_cmp = (category_order.index(a[:category]) || 99) <=> (category_order.index(b[:category]) || 99)
  if cat_cmp == 0
    # NaN means the bench printed no speed claim; Float64#<=> returns nil for
    # NaN and Array#sort raises on that, so rank it lowest explicitly.
    rank_a = a[:best_ratio].nan? ? -1.0 : a[:best_ratio]
    rank_b = b[:best_ratio].nan? ? -1.0 : b[:best_ratio]
    rank_b <=> rank_a
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
  verdict = if r[:best_ratio].nan?
              "n/a"
            elsif r[:best_ratio] >= 5.0
              "significant"
            elsif r[:best_ratio] >= 2.0
              "moderate"
            else
              "negligible"
            end
  ratio_text = r[:best_ratio].nan? ? "-" : sprintf("%.2f", r[:best_ratio])

  puts "  #{sprintf("%-12s", r[:category])}  #{sprintf("%-8s", r[:rule])}  #{sprintf("%-30s", r[:description])}  #{sprintf("%-10s", ratio_text)}  #{verdict}"
end

puts ""
exit 0

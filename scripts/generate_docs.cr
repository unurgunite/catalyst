require "../src/catalyst"

module DocsGenerator
  extend self

  def run
    Dir.mkdir_p("docs/rules")

    rules = Catalyst::Rule.all

    if rules.empty?
      puts "No rules loaded"
      return
    end

    rules.each do |rule|
      generate_rule_doc(rule)
    end

    File.write("docs/rules/README.md", generate_index(rules))
    puts "Generated docs for #{rules.size} rules"
  end

  private def generate_rule_doc(rule)
    id = rule.id
    fix = rule.auto_fixable? ? "✅" : "❌"
    bench_path = bench_readme_path(id)

    content = String.build do |io|
      io << "# #{id} — #{rule.description}\n\n"
      io << "Severity: #{rule.severity} | Confidence: #{rule.confidence} | Auto-fix: #{fix}\n\n"
      io << rule.description << "\n\n"
      if bench_path
        io << "Benchmark: [#{bench_path}](#{bench_path})\n"
      end
    end

    File.write("docs/rules/#{id}.md", content)
    puts "  Generated docs/rules/#{id}.md"
  end

  private def generate_index(rules)
    String.build do |io|
      io << "# Catalyst Rules\n\n"
      io << "| ID | Rule | Severity | Confidence | Fix |\n"
      io << "|----|------|----------|------------|-----|\n"
      rules.each do |r|
        fix = r.auto_fixable? ? "✅" : "❌"
        io << "| #{r.id} | #{r.description} | #{r.severity} | #{r.confidence} | #{fix} |\n"
      end
      io << "\nTotal rules: #{rules.size}\n"
    end
  end

  private def bench_readme_path(rule_id) : String?
    dir = "cat-#{rule_id.split('-').last.rjust(3, '0')}"
    path = "bench/#{dir}/README.md"
    File.exists?(path) ? "../../#{path}" : nil
  end
end

if PROGRAM_NAME.ends_with?("generate_docs")
  DocsGenerator.run
end

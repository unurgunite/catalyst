require "file_utils"
require "compiler/crystal/syntax"

module Catalyst
  # # Collects source files, parses with `Crystal::Parser`, dispatches AST to rules.
  class Runner
    @rules : Array(Rule)
    # # Number of files that could not be read or parsed on the last run.
    # # Non-zero means the result set may be incomplete, so `--ci` must not
    # # report success on it.
    getter errors : Int32 = 0

    # # Initialize with config and CLI options. Loads active rules.
    # # Diagnostics go to `io` so tests can read them; the CLI passes STDERR.
    def initialize(@config : Config, @options : Options, @io : IO = STDERR)
      @rules = load_rules
    end

    # # Process all paths and return findings.
    def run(paths : Array(String)) : Array(Result)
      @errors = 0
      effective_paths = paths.empty? ? @config.paths : paths
      files = collect_files(effective_paths)
      results = [] of Result
      sources = {} of String => Array(String)

      files.each do |file|
        findings = analyze_file(file, sources)
        results.concat(findings) if findings
      end

      finish(results, sources)
    end

    # # Analyze one file and record its lines for inline suppression.
    ##
    # # Returns nil when the file could not be read or parsed; the error is
    # # already counted and reported.
    private def analyze_file(file : String, sources : Hash(String, Array(String))) : Array(Result)?
      source = File.read(file)
      sources[file] = source.lines
      parse_file(file, source)
    rescue ex : Crystal::SyntaxException
      report_error("parse error in #{file}", ex.message)
    rescue ex : File::Error | IO::Error
      report_error("cannot read #{file}", ex.message)
    end

    private def parse_file(file : String, source : String) : Array(Result)
      @rules.each(&.setup(file, source))
      context = Context.new(file, source)
      visitor = Visitors::FileVisitor.new(@rules, context)
      Crystal::Parser.new(source).parse.accept(visitor)
      visitor.results
    end

    # # A file that could not be analyzed makes the result set incomplete.
    private def report_error(what : String, message : String?) : Nil
      @errors += 1
      @io.puts "catalyst: #{what}: #{message}"
    end

    # # Apply the post-analysis pipeline: severity, suppression, baseline, fixes.
    private def finish(results : Array(Result), sources : Hash(String, Array(String))) : Array(Result)
      apply_severity_overrides(results)
      results = suppress_inline(results, sources)
      results = apply_baseline(results)
      apply_fixes(results) if @options.fix? || @options.dry_run?
      results
    end

    # # Write the baseline when asked, then keep only findings not in it.
    private def apply_baseline(results : Array(Result)) : Array(Result)
      if update_path = @options.update_baseline
        count = Baseline.write(update_path, results)
        @io.puts "catalyst: wrote #{count} findings to #{update_path}"
      end

      baseline_path = @options.update_baseline || @options.baseline
      return results unless baseline_path

      Baseline.new_findings(results, Baseline.load(baseline_path))
    end

    # # Drop findings silenced by `# catalyst:disable` comments placed
    # # on the finding's line or the line directly above it. A bare
    # # directive silences all rules; otherwise it lists rule IDs.
    private def suppress_inline(results : Array(Result), sources : Hash(String, Array(String))) : Array(Result)
      results.reject do |result|
        lines = sources[result.file]? || [] of String
        suppressed?(lines, result)
      end
    end

    private def suppressed?(lines : Array(String), result : Result) : Bool
      [result.line, result.line - 1].each do |lineno|
        next if lineno < 1 || lineno > lines.size
        if match = lines[lineno - 1].match(/#\s*catalyst:disable\b(.*)$/)
          ids = match[1].split(/[\s,]+/).reject(&.empty?)
          return true if ids.empty? || ids.includes?(result.rule_id)
        end
      end
      false
    end

    private def apply_fixes(results : Array(Result)) : Nil
      fixable = results.select(&.fix_replacement)
      if fixable.empty?
        @io.puts "catalyst: nothing to fix" if @options.fix? || @options.dry_run?
        return
      end

      fixable.group_by(&.file).each { |file, file_results| fix_file(file, file_results) }
    end

    private def fix_file(file : String, file_results : Array(Result)) : Nil
      source = File.read(file)
      updated = rewrite(source, file, file_results)

      if updated == source
        @io.puts "catalyst: no changes for #{file}"
      elsif problem = parse_problem(updated)
        @io.puts "catalyst: skipped unsafe fix in #{file} — result would not parse: #{problem}"
      elsif @options.dry_run?
        @io.puts "catalyst: would fix #{file}"
      else
        write_fix(file, updated)
      end
    end

    # # Write the rewritten file, keeping an existing backup untouched.
    private def write_fix(file : String, updated : String) : Nil
      backup = "#{file}.bak"
      if File.exists?(backup)
        @io.puts "catalyst: backup #{backup} already exists — left untouched"
      else
        File.copy(file, backup)
      end

      File.write(file, updated)
      @io.puts "catalyst: fixed #{file} (backup: #{backup})"
    end

    # Applies each replacement to its line and returns the new source.
    private def rewrite(source : String, file : String, file_results : Array(Result)) : String
      lines = source.lines
      applied_lines = Set(Int32).new

      file_results.sort_by { |result| -result.line }.each do |result|
        apply_replacement(lines, file, result, applied_lines)
      end

      # `String#lines` drops the trailing newline; writing the join back
      # unchanged would silently strip it from every fixed file.
      updated = lines.join("\n")
      updated += "\n" if source.ends_with?('\n')
      updated
    end

    # # Replace one line, reporting why a replacement was not applied.
    ##
    # # One line may host several findings. Applying the whole line twice
    # # would drop the second fix, so only the first replacement per line is
    # # applied and the rest are reported as skipped.
    private def apply_replacement(lines : Array(String), file : String,
                                  result : Result, applied_lines : Set(Int32)) : Nil
      return if result.line < 1 || result.line > lines.size
      return unless replacement = result.fix_replacement

      unless applied_lines.add?(result.line)
        @io.puts "catalyst: skipped #{result.rule_id} at #{file}:#{result.line} — same line already fixed"
        return
      end

      lines[result.line - 1] = replacement
    end

    # Returns a parse error message, or nil when `source` parses cleanly.
    private def parse_problem(source : String) : String?
      Crystal::Parser.new(source).parse
      nil
    rescue ex : Crystal::SyntaxException
      ex.message
    end

    private def collect_files(paths : Array(String)) : Array(String)
      files = [] of String
      paths.each { |path| expand_path(path, files) }
      files = dedupe(files)
      files.reject! { |file| ignored?(file) }
      files.sort!
      files
    end

    # # Add every `.cr` file under one path argument to `files`.
    ##
    # # Forward slashes only: `Dir.glob` treats backslashes as escapes, so
    # # Windows paths must be normalized first. No `File.join` either — it
    # # would reintroduce a backslash separator on Windows.
    private def expand_path(path : String, files : Array(String)) : Nil
      normalized = path.gsub("\\", "/")
      if File.directory?(normalized)
        Dir.glob("#{normalized}/**/*.cr").each { |file| files << file }
      elsif File.file?(normalized) && normalized.ends_with?(".cr")
        files << normalized
      else
        # A typo'd path would otherwise shrink the file list silently and
        # produce a clean exit 0 on code that was never analyzed.
        @io.puts "catalyst: no such file or directory: #{path}"
        @errors += 1
      end
    end

    private def ignored?(file : String) : Bool
      @config.ignore.any? { |pattern| File.match?(pattern.gsub("\\", "/"), file) }
    end

    # # Build the active rule list from defaults, CLI allow/deny lists and
    # # config overrides. Opt-in rules are reachable through both `--rules`
    # # and `rules: {CAT-XXX: {enabled: true}}`.
    # # Test seam: `collect_files` is private but the de-duplication rule is
    # # exactly what regressed on Windows, so specs assert it directly.
    def collect_files_for_test(paths : Array(String)) : Array(String)
      collect_files(paths)
    end

    # # Drop repeated files, keeping the first spelling of each.
    # # `File.same?` compares the underlying file, so separator style, `.`
    # # segments and (on Windows) casing do not create duplicates. It raises
    # # for paths that no longer exist, hence the fallback to spelling.
    private def dedupe(files : Array(String)) : Array(String)
      kept = [] of String
      files.each do |file|
        duplicate = kept.any? { |other| same_file?(file, other) }
        kept << file unless duplicate
      end
      kept
    end

    # # `File.same?` raises for a path that vanished between glob and here.
    private def same_file?(one : String, two : String) : Bool
      File.same?(one, two)
    rescue
      one == two
    end

    private def load_rules : Array(Rule)
      rules = Rule.all.select(&.enabled_by_default?)
      rules = apply_allowlist(rules)
      rules = apply_denylist(rules)
      rules = apply_config_rules(rules)
      configure_rules(rules)
      rules
    end

    # # `--rules` replaces the default set with exactly the named rules.
    private def apply_allowlist(rules : Array(Rule)) : Array(Rule)
      return rules unless allowlist = @options.rules

      wanted = allowlist.map(&.strip).reject(&.empty?).to_set
      # Compare against every registered rule, not just default-on ones,
      # otherwise `--rules CAT-038` warns "unknown" and then yields nothing.
      (wanted - Rule.all.map(&.id).to_set).each do |id|
        @io.puts "catalyst: warning: unknown rule #{id} in --rules"
      end
      Rule.all.select { |rule| wanted.includes?(rule.id) }
    end

    private def apply_denylist(rules : Array(Rule)) : Array(Rule)
      return rules unless denylist = @options.ignore

      denied = denylist.map(&.strip).reject(&.empty?).to_set
      rules.reject { |rule| denied.includes?(rule.id) }
    end

    # # A config entry can switch a rule off or re-add an opt-in rule.
    private def apply_config_rules(rules : Array(Rule)) : Array(Rule)
      @config.rules.each do |id, rule_config|
        if rule_config.enabled?
          if rule = Rule.all.find { |candidate| candidate.id == id }
            rules << rule unless rules.any? { |active| active.id == id }
          end
        else
          rules.reject! { |rule| rule.id == id }
        end
      end
      rules
    end

    private def configure_rules(rules : Array(Rule)) : Nil
      rules.each do |rule|
        params = @config.rules[rule.id]?.try(&.params)
        rule.configure(params) if params
      end
    end

    private def apply_severity_overrides(results : Array(Result)) : Nil
      overrides = severity_overrides
      return if overrides.empty?

      # NOTE: Result is a struct, so mutate the copy and store it back —
      # `results[i].severity = x` would silently write into a temporary.
      results.map! do |result|
        if override = overrides[result.rule_id]?
          result.severity = override
        end
        result
      end
    end

    private def severity_overrides : Hash(String, String)
      overrides = {} of String => String
      @config.rules.each do |id, rule_config|
        if severity = rule_config.severity
          overrides[id] = severity
        end
      end
      overrides
    end
  end
end

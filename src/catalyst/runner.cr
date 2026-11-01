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
    def initialize(@config : Config, @options : Options)
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
        source = File.read(file)
        sources[file] = source.lines
        context = Context.new(file, source)

        @rules.each(&.setup(file, source))

        parser = Crystal::Parser.new(source)
        nodes = parser.parse

        visitor = Visitors::FileVisitor.new(@rules, context)
        nodes.accept(visitor)

        results.concat(visitor.results)
      rescue ex : Crystal::SyntaxException
        @errors += 1
        STDERR.puts "catalyst: parse error in #{file}: #{ex.message}"
      rescue ex : File::Error | IO::Error
        @errors += 1
        STDERR.puts "catalyst: cannot read #{file}: #{ex.message}"
      end

      apply_severity_overrides(results)
      results = suppress_inline(results, sources)

      if update_path = @options.update_baseline
        count = Baseline.write(update_path, results)
        STDERR.puts "catalyst: wrote #{count} findings to #{update_path}"
      end

      if baseline_path = (@options.update_baseline || @options.baseline)
        known = Baseline.load(baseline_path)
        results = Baseline.new_findings(results, known)
      end

      if @options.fix?
        apply_fixes(results)
      end

      results
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
        STDERR.puts "catalyst: nothing to fix" if @options.fix? || @options.dry_run?
        return
      end

      fixable.group_by(&.file).each do |file, file_results|
        fix_file(file, file_results)
      end
    end

    private def fix_file(file : String, file_results : Array(Result)) : Nil
      source = File.read(file)
      updated = rewrite(source, file, file_results)

      if updated == source
        STDERR.puts "catalyst: no changes for #{file}"
        return
      end

      if problem = parse_problem(updated)
        STDERR.puts "catalyst: skipped unsafe fix in #{file} — result would not parse: #{problem}"
        return
      end

      if @options.dry_run?
        STDERR.puts "catalyst: would fix #{file}"
        return
      end

      backup = "#{file}.bak"
      if File.exists?(backup)
        STDERR.puts "catalyst: backup #{backup} already exists — left untouched"
      else
        File.copy(file, backup)
      end

      File.write(file, updated)
      STDERR.puts "catalyst: fixed #{file} (backup: #{backup})"
    end

    # Applies each replacement to its line and returns the new source.
    private def rewrite(source : String, file : String, file_results : Array(Result)) : String
      lines = source.lines

      # One line may host several findings (e.g. CAT-019 + CAT-039). Applying
      # the whole line twice would drop the second fix, so only the first
      # replacement per line is applied and the rest are reported as skipped.
      applied_lines = Set(Int32).new
      file_results.sort_by { |result| -result.line }.each do |result|
        next if result.line < 1 || result.line > lines.size
        next unless replacement = result.fix_replacement
        unless applied_lines.add?(result.line)
          STDERR.puts "catalyst: skipped #{result.rule_id} at #{file}:#{result.line} — same line already fixed"
          next
        end
        lines[result.line - 1] = replacement
      end

      # `String#lines` drops the trailing newline; writing the join back
      # unchanged would silently strip it from every fixed file.
      updated = lines.join("\n")
      updated += "\n" if source.ends_with?('\n')
      updated
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
      paths.each do |path|
        # Forward slashes: Dir.glob treats backslashes as escapes, so
        # Windows paths must be normalized before globbing.
        normalized = path.gsub("\\", "/")
        if File.directory?(normalized)
          # NOTE: no File.join — it would reintroduce a backslash
          # separator on Windows and break the glob again.
          Dir.glob("#{normalized}/**/*.cr").each { |file| files << file }
        elsif File.file?(normalized) && normalized.ends_with?(".cr")
          files << normalized
        else
          # A typo'd path would otherwise shrink the file list silently and
          # produce a clean exit 0 on code that was never analyzed.
          STDERR.puts "catalyst: no such file or directory: #{path}"
          @errors += 1
        end
      end
      # De-dupe by file identity, not by string spelling: the same file can
      # arrive as `C:\dir\a.cr` (File.join), `C:/dir/a.cr` (normalized) or
      # with different casing, and a directory plus a file inside it yields
      # two entries anyway. Comparing spellings let the file be analyzed —
      # and fixed — twice on Windows. `File.same?` answers for the platform.
      files = dedupe(files)
      files.reject! do |file|
        @config.ignore.any? { |pattern| File.match?(pattern.gsub("\\", "/"), file) }
      end
      files.sort!
      files
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

      if allowlist = @options.rules
        wanted = allowlist.map(&.strip).reject(&.empty?).to_set
        # Compare against every registered rule, not just default-on ones,
        # otherwise `--rules CAT-038` warns "unknown" and then yields nothing.
        known = Rule.all.map(&.id).to_set
        (wanted - known).each do |id|
          STDERR.puts "catalyst: warning: unknown rule #{id} in --rules"
        end
        rules = Rule.all.select { |rule| wanted.includes?(rule.id) }
      end

      if denylist = @options.ignore
        denied = denylist.map(&.strip).reject(&.empty?).to_set
        rules.reject! { |rule| denied.includes?(rule.id) }
      end

      @config.rules.each do |id, rule_config|
        if rule_config.enabled?
          # Re-add an opt-in rule the config asks for.
          if rule = Rule.all.find { |candidate| candidate.id == id }
            rules << rule unless rules.any? { |active| active.id == id }
          end
        else
          rules.reject! { |rule| rule.id == id }
        end
      end

      rules.each do |rule|
        params = @config.rules[rule.id]?.try(&.params)
        rule.configure(params) if params
      end

      rules
    end

    private def apply_severity_overrides(results : Array(Result)) : Nil
      overrides = {} of String => String
      @config.rules.each do |id, rule_config|
        if severity = rule_config.severity
          overrides[id] = severity
        end
      end
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
  end
end

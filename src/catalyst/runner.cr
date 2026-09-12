require "file_utils"
require "compiler/crystal/syntax"

module Catalyst
  # # Collects source files, parses with `Crystal::Parser`, dispatches AST to rules.
  class Runner
    @rules : Array(Rule)

    # # Initialize with config and CLI options. Loads active rules.
    def initialize(@config : Config, @options : Options)
      @rules = load_rules
    end

    # # Process all paths and return findings.
    def run(paths : Array(String)) : Array(Result)
      effective_paths = paths.empty? ? @config.paths : paths
      files = collect_files(effective_paths)
      results = [] of Result

      files.each do |file|
        source = File.read(file)
        context = Context.new(file, source)

        @rules.each(&.setup(file, source))

        parser = Crystal::Parser.new(source)
        nodes = parser.parse

        visitor = Visitors::FileVisitor.new(@rules, context)
        nodes.accept(visitor)

        results.concat(visitor.results)
      rescue ex : Crystal::SyntaxException
        STDOUT.puts "catalyst: parse error in #{file}: #{ex.message}"
      rescue ex
        STDOUT.puts "catalyst: error processing #{file}: #{ex.message}"
      end

      apply_severity_overrides(results)

      if @options.fix?
        apply_fixes(results)
      end

      results
    end

    private def apply_fixes(results : Array(Result)) : Nil
      fixable = results.select(&.fix_replacement)
      return if fixable.empty?

      by_file = fixable.group_by(&.file)

      by_file.each do |file, file_results|
        source = File.read(file)
        lines = source.lines

        file_results.sort_by! { |result| -result.line }

        file_results.each do |result|
          next if result.line < 1 || result.line > lines.size
          if replacement = result.fix_replacement
            lines[result.line - 1] = replacement
          end
        end

        backup = "#{file}.bak"
        File.copy(file, backup)

        File.write(file, lines.join("\n"))
        STDOUT.puts "catalyst: fixed #{file} (backup: #{backup})"
      end
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
        end
      end
      files.reject! do |file|
        @config.ignore.any? { |pattern| File.match?(pattern, file) }
      end
      files.sort!
      files
    end

    private def load_rules : Array(Rule)
      rules = Rule.all.select(&.enabled_by_default?)

      if allowlist = @options.rules
        wanted = allowlist.map(&.strip).reject(&.empty?).to_set
        known = rules.map(&.id).to_set
        (wanted - known).each do |id|
          STDERR.puts "catalyst: warning: unknown rule #{id} in --rules"
        end
        rules.select! { |rule| wanted.includes?(rule.id) }
      end

      if denylist = @options.ignore
        denied = denylist.map(&.strip).reject(&.empty?).to_set
        rules.reject! { |rule| denied.includes?(rule.id) }
      end

      @config.rules.each do |id, rule_config|
        unless rule_config.enabled?
          rules.reject! { |rule| rule.id == id }
        end
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

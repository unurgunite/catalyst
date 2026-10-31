require "option_parser"

module Catalyst
  # # CLI entry point. Parses ARGV, loads config, runs analysis, formats output.
  class CLI
    # # Parse arguments and execute the analysis pipeline.
    ##
    # # Returns exit code (0 = success, 1 = findings in CI mode, 2 = error).
    # # Build options from ARGV. Returns nil when the arguments are invalid
    # # (the message is already on STDERR); `options.help?` and
    # # `options.version?` short-circuit before analysis.
    # # NOTE: no `exit` here — this class is a library and exiting would kill
    # # the embedding host (specs, doc generators, wrappers).
    private def self.parse_options(args : Array(String)) : Options?
      options = Options.new
      config_path = ".catalyst.yml"

      begin
        OptionParser.parse(args) do |parser|
          parser.banner = "Usage: catalyst [options] <path> [path...]"

          parser.banner = "Usage: catalyst [options] <path> [path...]"
          parser.on("--config PATH", "Path to config file") { |v| config_path = v }
          parser.on("--format FORMAT", "Output format: terminal|json|sarif") { |v| options.format = v }
          parser.on("--severity LEVEL", "Minimum severity: error|warning|info|hint") { |v| options.min_severity = v }
          parser.on("--fix", "Apply safe auto-fixes") { options.fix = true }
          parser.on("--dry-run", "Show what --fix would change without writing") { options.dry_run = true }
          parser.on("--ci", "CI mode — exit code 1 on any finding") { options.ci = true }
          parser.on("--rules RULES", "Comma-separated rule IDs to enable") { |v| options.rules = v.split(",") }
          parser.on("--ignore RULES", "Comma-separated rule IDs to disable") { |v| options.ignore = v.split(",") }
          parser.on("--baseline PATH", "Report only findings absent from baseline file") { |v| options.baseline = v }
          parser.on("--update-baseline PATH", "Write current findings as baseline, then report only new ones") { |v| options.update_baseline = v }
          parser.on("--list-rules", "List all available rules and exit") { options.list_rules = true }
          parser.on("--version", "Show version") { puts "catalyst v#{VERSION}"; options.version = true }
          parser.on("-h", "--help", "Show help") { puts parser; options.help = true }
        end
      rescue ex : OptionParser::Exception
        STDERR.puts "catalyst: #{ex.message}"
        STDERR.puts "catalyst: run with --help for usage"
        return nil
      end

      options.config_path = config_path
      options
    end

    def self.run(args : Array(String) = ARGV) : Int32
      options = parse_options(args)
      return 2 unless options

      return 0 if options.version? || options.help?

      if options.list_rules?
        list_rules
        return 0
      end

      if Rule.all.empty?
        STDERR.puts "catalyst: no rules loaded — refusing to report a clean result."
        STDERR.puts "catalyst: hint: rebuild from the repository root (`crystal build src/catalyst.cr`), then retry."
        return 2
      end

      config = resolve_config(options)
      return 2 unless config

      runner = Runner.new(config, options)
      begin
        results = runner.run(args)
      rescue ex : ConfigError
        # Corrupt baseline, unwritable baseline, unreadable input.
        STDERR.puts "catalyst: #{ex.message}"
        return 2
      end

      begin
        Formatter.for(config.format).output(results, STDOUT, config.severity)
      rescue ex : ArgumentError
        STDERR.puts "catalyst: #{ex.message}"
        return 2
      end

      # Never report success on input we failed to analyze.
      return 2 if runner.errors > 0

      return 1 if options.ci? && !results.empty?

      0
    end

    # # Load the config file and apply CLI overrides to it.
    # # Returns nil (after printing to STDERR) when config or flags are invalid.
    private def self.resolve_config(options : Options) : Config?
      config = ConfigLoader.load(options.config_path)
      apply_overrides(config, options)
    rescue ex : ConfigError
      STDERR.puts "catalyst: #{ex.message}"
      nil
    end

    # # Validate `--severity`/`--format` and let them win over the file.
    # # NOTE: `Config` is a struct — return the mutated copy, a plain
    # # in-place update inside this method would be discarded.
    private def self.apply_overrides(config : Config, options : Options) : Config?
      if severity = options.min_severity
        unless SEVERITY_LEVELS.includes?(severity)
          STDERR.puts "catalyst: invalid --severity #{severity.inspect} (expected #{SEVERITY_LEVELS.join("|")})"
          return nil
        end
        config.severity = severity
      end
      if format = options.format
        config.format = format
      end

      # Formatter.for falls back to terminal for unknown names, so a typo in
      # config or flags would silently change the output format.
      unless FORMATS.includes?(config.format.downcase)
        STDERR.puts "catalyst: invalid format #{config.format.inspect} (expected #{FORMATS.join("|")})"
        return nil
      end
      config
    end

    # # Test seam: `apply_overrides` is private but callers (specs) need to
    # # assert the resolved config, since `Config` is a struct.
    def self.apply_overrides_for_test(config : Config, options : Options) : Config?
      apply_overrides(config, options)
    end

    # # Severity levels, most to least severe.
    SEVERITY_LEVELS = %w[error warning info hint]
    # # Supported output formats.
    FORMATS = %w[terminal json sarif]

    private def self.list_rules
      if Rule.all.empty?
        puts "No rules loaded"
      else
        puts "Available rules:"
        Rule.all.each do |rule|
          tag = rule.enabled_by_default? ? "" : " [opt-in]"
          puts "  #{rule.id.ljust(8)} #{rule.severity.ljust(7)} #{rule.description}#{tag}"
        end
      end
    end
  end

  # # CLI flags and options parsed from ARGV.
  struct Options
    # # Config file path from `--config`.
    property config_path : String = ".catalyst.yml"
    # # Output format from `--format`; nil means use the config value.
    property format : String? = nil
    # # Minimum severity from `--severity`; nil means use the config value.
    property min_severity : String? = nil
    # # Apply safe auto-fixes.
    property? fix : Bool = false
    # # Report what `--fix` would change without writing anything.
    property? dry_run : Bool = false
    # # CI mode — exit code 1 on findings.
    property? ci : Bool = false
    # # Comma-separated rule IDs to enable (optional).
    property rules : Array(String)? = nil
    # # Comma-separated rule IDs to disable (optional).
    property ignore : Array(String)? = nil
    # # Baseline file path: report only findings absent from it.
    property baseline : String? = nil
    # # Baseline file path to (re)write from current findings.
    property update_baseline : String? = nil
    # # List all rules and exit.
    property? list_rules : Bool = false
    # # `--version` was passed; print and exit 0.
    property? version : Bool = false
    # # `--help` was passed; print and exit 0.
    property? help : Bool = false
  end
end

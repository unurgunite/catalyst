require "option_parser"

module Catalyst
  # # CLI entry point. Parses ARGV, loads config, runs analysis, formats output.
  class CLI
    # # Parse arguments and execute the analysis pipeline.
    ##
    # # Returns exit code (0 = success, 1 = findings in CI mode, 2 = error).
    def self.run(args : Array(String) = ARGV) : Int32
      options = Options.new
      config_path = ".catalyst.yml"

      OptionParser.parse(args) do |parser|
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
        parser.on("--version", "Show version") { puts "catalyst v#{VERSION}"; exit 0 }
        parser.on("-h", "--help", "Show help") { puts parser; exit 0 }
      end

      if options.list_rules?
        list_rules
        return 0
      end

      if Rule.all.empty?
        STDERR.puts "catalyst: no rules loaded — refusing to report a clean result."
        STDERR.puts "catalyst: hint: rebuild from the repository root (`crystal build src/catalyst.cr`), then retry."
        return 2
      end

      begin
        config = ConfigLoader.load(config_path)
      rescue ex : ConfigError
        STDERR.puts "catalyst: #{ex.message}"
        return 2
      end

      # CLI flags win over the config file; the config is the fallback.
      if severity = options.min_severity
        unless SEVERITY_LEVELS.includes?(severity)
          STDERR.puts "catalyst: invalid --severity #{severity.inspect} (expected #{SEVERITY_LEVELS.join("|")})"
          return 2
        end
        config.severity = severity
      end
      if format = options.format
        config.format = format
      end

      # Validate before a long run: Formatter.for falls back to terminal for
      # anything it does not know, so a typo would silently change output.
      unless FORMATS.includes?(config.format.downcase)
        STDERR.puts "catalyst: invalid format #{config.format.inspect} (expected #{FORMATS.join("|")})"
        return 2
      end

      runner = Runner.new(config, options)
      results = runner.run(args)

      begin
        formatter = Formatter.for(config.format)
        formatter.output(results, STDOUT, config.severity)
      rescue ex : ArgumentError
        STDERR.puts "catalyst: #{ex.message}"
        return 2
      end

      if options.ci? && !results.empty?
        return 1
      end
      0
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
  end
end

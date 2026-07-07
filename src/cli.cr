require "option_parser"

module Catalyst
  ## CLI entry point. Parses ARGV, loads config, runs analysis, formats output.
  class CLI
    ## Parse arguments and execute the analysis pipeline.
    ##
    ## Returns exit code (0 = success, 1 = findings in CI mode).
    def self.run(args : Array(String) = ARGV) : Int32
      options = Options.new
      config_path = ".catalyst.yml"

      OptionParser.parse(args) do |parser|
        parser.banner = "Usage: catalyst [options] <path> [path...]"

        parser.on("--config PATH", "Path to config file") { |v| config_path = v }
        parser.on("--format FORMAT", "Output format: terminal|json|sarif") { |v| options.format = v }
        parser.on("--severity LEVEL", "Minimum severity: error|warning|info|hint") { |v| options.min_severity = v }
        parser.on("--fix", "Apply safe auto-fixes") { options.fix = true }
        parser.on("--ci", "CI mode — exit code 1 on any finding") { options.ci = true }
        parser.on("--rules RULES", "Comma-separated rule IDs to enable") { |v| options.rules = v.split(",") }
        parser.on("--ignore RULES", "Comma-separated rule IDs to disable") { |v| options.ignore = v.split(",") }
        parser.on("--list-rules", "List all available rules and exit") { options.list_rules = true }
        parser.on("--version", "Show version") { puts "catalyst v#{VERSION}"; exit 0 }
        parser.on("-h", "--help", "Show help") { puts parser; exit 0 }
      end

      if options.list_rules
        list_rules
        return 0
      end

      config = ConfigLoader.load(config_path)
      runner = Runner.new(config, options)
      results = runner.run(args)

      formatter = Formatter.for(options.format || config.format)
      formatter.output(results, STDOUT, config.severity)

      if options.ci && results.any?
        return 1
      end
      0
    end

    private def self.list_rules
      if Rule.all.empty?
        puts "No rules loaded"
      else
        puts "Available rules:"
        Rule.all.each do |rule|
          puts "  #{rule.id.ljust(8)} #{rule.severity.ljust(7)} #{rule.description}"
        end
      end
    end
  end

  ## CLI flags and options parsed from ARGV.
  struct Options
    ## Output format: terminal, json, or sarif.
    property format : String = "terminal"
    ## Minimum severity to display.
    property min_severity : String = "hint"
    ## Apply safe auto-fixes.
    property fix : Bool = false
    ## CI mode — exit code 1 on findings.
    property ci : Bool = false
    ## Comma-separated rule IDs to enable (optional).
    property rules : Array(String)? = nil
    ## Comma-separated rule IDs to disable (optional).
    property ignore : Array(String)? = nil
    ## List all rules and exit.
    property list_rules : Bool = false
  end
end

require "colorize"

module Catalyst
  module Formatters
    # # Colorized human-readable output to STDOUT.
    class Terminal < Formatter
      # # ANSI color codes per severity level.
      SEVERITY_COLORS = {
        "error"   => :red,
        "warning" => :yellow,
        "info"    => :cyan,
        "hint"    => :dim,
      }

      # # Write findings as colorized lines with severity, location, and suggestion.
      def output(results : Array(Result), io : IO, min_severity : String) : Nil
        filtered = filter_by_severity(results, min_severity)
        return if filtered.empty?

        filtered.each do |result|
          color = SEVERITY_COLORS[result.severity]? || :default
          io.puts "#{result.file}:#{result.line}:#{result.column} — #{result.rule_id}: #{result.message.colorize(color)}"
          if result.suggestion
            io.puts "  Suggestion: #{result.suggestion}"
          end
          io.puts "  [help: https://catalyst.dev/rules/#{result.rule_id}]"
          io.puts
        end

        by_severity = filtered.group_by(&.severity)
        parts = by_severity.map { |severity, list| "#{list.size} #{severity}" }
        io.puts "Found #{filtered.size} issue#{filtered.size == 1 ? "" : "s"} (#{parts.join(", ")})"
      end

      private def filter_by_severity(results : Array(Result), min_severity : String) : Array(Result)
        levels = %w(error warning info hint)
        min_idx = levels.index(min_severity) || 0
        results.select { |result| (levels.index(result.severity) || 0) >= min_idx }
      end
    end
  end
end

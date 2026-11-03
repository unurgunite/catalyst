require "colorize"

module Catalyst
  module Formatters
    # # Colorized human-readable output to STDOUT.
    class Terminal < Formatter
      # # ANSI color codes per severity level. The list is `Colorize::COLORS`;
      # # `:dark_gray` is Crystal's dim grey (there is no `:dim`/`:light_black`).
      SEVERITY_COLORS = {
        "error"   => :red,
        "warning" => :yellow,
        "info"    => :cyan,
        "hint"    => :dark_gray,
      }

      # # Write findings as colorized lines with severity, location, and suggestion.
      def output(results : Array(Result), io : IO, min_severity : String) : Nil
        filtered = filter_by_severity(results, min_severity)
        return if filtered.empty?

        filtered.each { |result| write_result(io, result) }
        write_summary(io, filtered)
      end

      # # One finding: location line, optional suggestion, help link, blank line.
      private def write_result(io : IO, result : Result) : Nil
        color = SEVERITY_COLORS[result.severity]? || :default
        io.puts "#{result.file}:#{result.line}:#{result.column} — #{result.rule_id}: #{result.message.colorize(color)}"
        io.puts "  Suggestion: #{result.suggestion}" if result.suggestion
        io.puts "  [help: https://github.com/unurgunite/catalyst/wiki/#{result.rule_id}]"
        io.puts
      end

      private def write_summary(io : IO, filtered : Array(Result)) : Nil
        parts = filtered.group_by(&.severity).map { |severity, list| "#{list.size} #{severity}" }
        io.puts "Found #{filtered.size} issue#{filtered.size == 1 ? "" : "s"} (#{parts.join(", ")})"
      end
    end
  end
end

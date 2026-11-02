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

        filtered.each do |result|
          color = SEVERITY_COLORS[result.severity]? || :default
          io.puts "#{result.file}:#{result.line}:#{result.column} — #{result.rule_id}: #{result.message.colorize(color)}"
          if result.suggestion
            io.puts "  Suggestion: #{result.suggestion}"
          end
          io.puts "  [help: https://github.com/unurgunite/catalyst/wiki/#{result.rule_id}]"
          io.puts
        end

        by_severity = filtered.group_by(&.severity)
        parts = by_severity.map { |severity, list| "#{list.size} #{severity}" }
        io.puts "Found #{filtered.size} issue#{filtered.size == 1 ? "" : "s"} (#{parts.join(", ")})"
      end
    end
  end
end

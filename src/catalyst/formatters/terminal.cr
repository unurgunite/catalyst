require "colorize"

module Catalyst
  module Formatters
    class Terminal < Formatter
      SEVERITY_COLORS = {
        "error"   => :red,
        "warning" => :yellow,
        "info"    => :cyan,
        "hint"    => :dim,
      }

      def output(results : Array(Result), io : IO, min_severity : String) : Nil
        filtered = filter_by_severity(results, min_severity)
        return if filtered.empty?

        filtered.each do |r|
          color = SEVERITY_COLORS[r.severity]? || :default
          io.puts "#{r.file}:#{r.line}:#{r.column} — #{r.rule_id}: #{r.message.colorize(color)}"
          if r.suggestion
            io.puts "  Suggestion: #{r.suggestion}"
          end
          io.puts "  [help: https://catalyst.dev/rules/#{r.rule_id}]"
          io.puts
        end

        by_severity = filtered.group_by(&.severity)
        parts = by_severity.map { |sev, list| "#{list.size} #{sev}" }
        io.puts "Found #{filtered.size} issue#{filtered.size == 1 ? "" : "s"} (#{parts.join(", ")})"
      end

      private def filter_by_severity(results : Array(Result), min_severity : String) : Array(Result)
        levels = %w(error warning info hint)
        min_idx = levels.index(min_severity) || 0
        results.select { |r| (levels.index(r.severity) || 0) >= min_idx }
      end
    end
  end
end

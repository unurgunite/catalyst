module Catalyst
  module Rules
    # # Detects `Time.local(...)` and suggests `Time.utc(...)`.
    ##
    # # `Time.local` creates time in local timezone (slower due to timezone
    # # conversion). `Time.utc` creates in UTC (faster, no conversion needed).
    # # Use `Time.utc` when local timezone is not required.
    class TimeLocalToUtc < Rule
      def id : String
        "CAT-017"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `Time.utc` instead of `Time.local` when local timezone is not required"
      end

      def auto_fixable? : Bool
        true
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "local"
        return [] of Result unless (obj = node.obj).is_a?(Crystal::Path)
        return [] of Result unless obj.names == ["Time"]

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0
        line_text = context.line_text(line)
        fix = line_text.gsub("Time.local", "Time.utc")

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `Time.utc` instead of `Time.local` when local timezone is not required",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `Time.local(...)` with `Time.utc(...)`",
          confidence: "medium",
          fix_replacement: fix,
        )]
      end

      Rule.all << self.new
    end
  end
end

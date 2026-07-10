module Catalyst
  module Rules
    class LoggingBlock < Rule
      LOG_LEVELS = {"debug", "info", "warn", "error", "fatal", "enbug"}

      def id : String
        "CAT-037"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use block form for logging with interpolation"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless LOG_LEVELS.includes?(node.name)
        return [] of Result unless node.args.size > 0
        return [] of Result unless node.args.first.is_a?(Crystal::StringInterpolation)
        return [] of Result unless node.block.nil?

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        receiver = node.obj ? "#{node.obj}." : ""

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use block form for logging: `#{receiver}#{node.name} { ... }` instead of `#{receiver}#{node.name}(\"...\#{...}\")`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Use block form to avoid string interpolation overhead when log level is disabled",
          confidence: "high"
        )]
      end

      Rule.all << self.new
    end
  end
end

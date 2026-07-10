module Catalyst
  module Rules
    class SleepZeroToYield < Rule
      def id : String
        "CAT-042"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `Fiber.yield` instead of `sleep(0)`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "sleep"
        return [] of Result unless node.args.size == 1

        arg = node.args.first
        return [] of Result unless arg.is_a?(Crystal::NumberLiteral)
        return [] of Result unless arg.value == "0"

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `Fiber.yield` instead of `sleep(0)`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `sleep(0)` with `Fiber.yield`",
          confidence: "high",
        )]
      end

      Rule.all << self.new
    end
  end
end

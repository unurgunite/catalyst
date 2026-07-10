module Catalyst
  module Rules
    class PowerToMath < Rule
      def id : String
        "CAT-044"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `x * x` instead of `x ** 2` and `Math.sqrt` instead of `** 0.5`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "**"
        return [] of Result unless node.args.size == 1
        return [] of Result unless node.obj

        arg = node.args.first
        return [] of Result unless arg.is_a?(Crystal::NumberLiteral)

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        case arg.value
        when "2"
          [Result.new(
            rule_id: id,
            severity: severity,
            message: "Use `x * x` instead of `x ** 2`",
            file: context.file,
            line: line,
            column: col,
            suggestion: "Replace `x ** 2` with `x * x`",
            confidence: "low",
          )]
        when "0.5"
          [Result.new(
            rule_id: id,
            severity: severity,
            message: "Use `Math.sqrt` instead of `** 0.5`",
            file: context.file,
            line: line,
            column: col,
            suggestion: "Replace `x ** 0.5` with `Math.sqrt(x)`",
            confidence: "low",
          )]
        else
          [] of Result
        end
      end

      Rule.all << self.new
    end
  end
end

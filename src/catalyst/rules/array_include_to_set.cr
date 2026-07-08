module Catalyst
  module Rules
    # # Detects `includes?` calls on arrays and suggests using a `Set`.
    ##
    # # `Array#includes?` is O(n) per call. When checking membership repeatedly
    # # (e.g. inside a loop), converting to a `Set` first makes each lookup O(1).
    class ArrayIncludeToSet < Rule
      def id : String
        "CAT-004"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `Set` instead of `Array#include?` in loops"
      end

      # # Check if node is an `includes?` call with exactly one argument.
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "includes?"
        return [] of Result unless node.args.size == 1

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `Set` instead of `Array#include?` in loops",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Convert the array to a `Set` before the loop: `ary.to_set`",
          confidence: "medium",
        )]
      end

      Rule.all << self.new
    end
  end
end

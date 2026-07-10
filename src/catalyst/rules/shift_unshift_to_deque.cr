module Catalyst
  module Rules
    # Detects `.shift` / `.unshift` calls on `Array` and suggests `Deque`.
    #
    # `Array#shift` and `Array#unshift` are O(n) because elements must
    # be shifted. `Deque` provides O(1) amortized shift/unshift.
    class ShiftUnshiftToDeque < Rule
      def id : String
        "CAT-005"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `Deque` instead of `Array` for shift/unshift operations"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "shift" || node.name == "unshift"
        return [] of Result unless node.obj

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `Deque` instead of `Array` for `#{node.name}` operations",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `Array` with `Deque` for efficient `#{node.name}`",
          confidence: "medium"
        )]
      end

      Rule.all << self.new
    end
  end
end

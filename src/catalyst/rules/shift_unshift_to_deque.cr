module Catalyst
  module Rules
    # Detects `.shift` / `.unshift` calls on `Array` inside loops and
    # suggests `Deque`.
    #
    # `Array#shift` and `Array#unshift` are O(n) because elements must
    # be shifted. `Deque` provides O(1) amortized shift/unshift.
    #
    # Outside loops (e.g. consuming a 2-3 element CLI argument list) the
    # rewrite only complicates the code, so the rule stays silent there.
    class ShiftUnshiftToDeque < Rule
      include LoopTracking

      def id : String
        "CAT-005"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `Deque` instead of `Array` for shift/unshift operations"
      end

      def setup(file_path : String, source : String) : Nil
        super
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        results = check_shift(node, context)
        track_enter(node)
        results
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        track_leave(node)
      end

      private def check_shift(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "shift" || node.name == "unshift"
        return [] of Result unless node.obj
        return [] of Result if @loop_depth == 0

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
          confidence: "medium",
        )]
      end

      Rule.all << self.new
    end
  end
end

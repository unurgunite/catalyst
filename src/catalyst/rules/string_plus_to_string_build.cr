module Catalyst
  module Rules
    # Detects `String#+`/`String#+=` inside loops and suggests `String.build`.
    #
    # String concatenation in loops creates a new string on each iteration,
    # leading to O(n²) allocations. `String.build` accumulates in a reusable buffer.
    class StringPlusToStringBuild < Rule
      include LoopTracking

      def id : String
        "CAT-010"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `String.build` instead of `String#+` in loops"
      end

      def setup(file_path : String, source : String) : Nil
        super
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        track_enter(node)
        return [] of Result unless in_loop?

        result = check_string_plus(node, context)
        result || [] of Result
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        track_leave(node)
      end

      # Check a single node for string concatenation patterns.
      private def check_string_plus(node : Crystal::ASTNode, context : Context) : Array(Result)?
        case node
        when Crystal::Call
          check_call_plus(node, context)
        when Crystal::OpAssign
          check_op_assign_plus(node, context)
        end
      end

      # Check Call node for + or +=.
      private def check_call_plus(node : Crystal::Call, context : Context) : Array(Result)?
        return nil unless node.name == "+" || node.name == "+="

        obj = node.obj
        return nil unless obj.is_a?(Crystal::Var) || obj.is_a?(Crystal::InstanceVar) || obj.is_a?(Crystal::Call) || obj.is_a?(Crystal::StringLiteral)

        return nil unless has_string_operand_call?(node)

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0
        op = node.name == "+=" ? "+=" : "+"

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `String.build` instead of `String##{op}` in loops",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace string concatenation with `String.build` block",
          confidence: "medium"
        )]
      end

      # Check OpAssign node for += (instance vars, class vars).
      private def check_op_assign_plus(node : Crystal::OpAssign, context : Context) : Array(Result)?
        return nil unless node.op == "+"

        target = node.target
        return nil unless target.is_a?(Crystal::InstanceVar) || target.is_a?(Crystal::Var) || target.is_a?(Crystal::Call)

        return nil unless has_string_operand_value?(node.value)

        line = node.location.try(&.line_number) || 0
        col = node.location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `String.build` instead of `String#+` in loops",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace string concatenation with `String.build` block",
          confidence: "medium"
        )]
      end

      private def has_string_operand_call?(node : Crystal::Call) : Bool
        return true if node.args.any?(Crystal::StringLiteral)
        return true if node.obj.is_a?(Crystal::StringLiteral)
        false
      end

      private def has_string_operand_value?(node : Crystal::ASTNode) : Bool
        node.is_a?(Crystal::StringLiteral)
      end

      Rule.all << self.new
    end
  end
end

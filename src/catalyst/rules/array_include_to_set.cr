module Catalyst
  module Rules
    # # Detects `includes?` calls on known arrays and suggests using a `Set`.
    ##
    # # `Array#includes?` is O(n) per call. When checking membership repeatedly
    # # (e.g. inside a loop), converting to a `Set` first makes each lookup O(1).
    # #
    # # Strict policy: only receivers proven to be arrays are flagged — array
    # # literals and variables assigned from array literals in the same file.
    # # Anything else (method params, call results, unknown variables) stays
    # # silent: without type information a `Set` suggestion may be actively
    # # wrong (e.g. the receiver is already a `Set`).
    # #
    # # Stays silent for `Range#includes?` (O(1) already — a `Set` would only
    # # add allocations) and for small array literals outside loops, where the
    # # conversion cost exceeds any lookup gain.
    class ArrayIncludeToSet < Rule
      include LoopTracking
      @loop_depth : Int32 = 0
      # # Local variable names assigned from array literals (name -> size).
      @array_sizes = {} of String => Int32

      def id : String
        "CAT-004"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `Set` instead of `Array#include?` in loops"
      end

      def setup(file_path : String, source : String) : Nil
        super
        @array_sizes.clear
      end

      # # Check if node is an `includes?` call with exactly one argument.
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        track_assign(node)
        # Depth must be accurate for this node, so the loop opener is counted
        # before the check. Counting after left `includes?` inside a loop
        # looking like top-level code.
        track_enter(node)
        check_includes(node, context)
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        track_leave(node)
      end

      private def check_includes(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = array_include_call(node)
        return [] of Result unless call

        [build_result(call, context)]
      end

      # # `X.includes?(y)` where `X` is provably an array and we are in a loop.
      ##
      # # Only receivers proven to be arrays are flagged: array literals and
      # # variables assigned from array literals in this file. Unknown
      # # receivers (params, call results, plain variables) stay silent —
      # # suggesting `Set` for something already O(1) (e.g. a `Set`) is worse
      # # than noise. Every non-array literal (Range with O(1) lookup,
      # # numbers, String substring search, ...) is out too.
      ##
      # # The suggestion is "convert before the loop", so it is only true
      # # when there is one. Reporting a one-shot lookup is what made this
      # # rule noisy on real projects: an `ARGV`-parsing branch is searched
      # # once and building a `Set` there only adds an allocation.
      private def array_include_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "includes?"
        return nil unless node.args.size == 1
        return nil unless array_receivers?(node)

        node
      end

      # # The receiver must be a provable array and the call must be in a loop.
      private def array_receivers?(call : Crystal::Call) : Bool
        receiver = call.obj
        return false unless receiver && @loop_depth > 0

        !array_receiver_size(unwrap(receiver)).nil?
      end

      private def build_result(call : Crystal::Call, context : Context) : Result
        Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `Set` instead of `Array#include?` in loops",
          file: context.file,
          line: call.location.try(&.line_number) || 0,
          column: call.name_location.try(&.column_number) || 0,
          suggestion: "Convert the array to a `Set` before the loop: `ary.to_set`",
          confidence: "medium",
        )
      end

      # # Array size if receiver is proven to be an array, else nil.
      # # Named literals (`Set{...}` parses as `ArrayLiteral` with a name)
      # # are not arrays.
      private def array_receiver_size(node : Crystal::ASTNode) : Int32?
        if node.is_a?(Crystal::ArrayLiteral)
          plain_array_size(node)
        elsif node.is_a?(Crystal::Var) ||
              node.is_a?(Crystal::InstanceVar) ||
              node.is_a?(Crystal::ClassVar)
          @array_sizes[node.name]?
        end
      end

      # # Size of an unnamed array literal (`Array{...}` counts), else nil.
      private def plain_array_size(literal : Crystal::ArrayLiteral) : Int32?
        name = literal.name
        if name.nil? || (name.is_a?(Crystal::Path) && name.names == ["Array"])
          literal.elements.size
        end
      end

      # # Strip grouping parentheses: `(1..5)` parses as Expressions.
      private def unwrap(node : Crystal::ASTNode) : Crystal::ASTNode
        if node.is_a?(Crystal::Expressions) && node.expressions.size == 1
          node.expressions.first
        else
          node
        end
      end

      # # Remember variables assigned from array literals; forget variables
      # # assigned anything else (e.g. reassigned to a `Set`).
      private def track_assign(node : Crystal::ASTNode) : Nil
        assignment = assignment_parts(node)
        return unless assignment

        target, value = assignment
        name = assign_name(target)
        return unless name

        size = array_literal_size(value)
        if size
          @array_sizes[name] = size
        else
          @array_sizes.delete(name)
        end
      end

      # # Target and value of an assignment, or nil for any other node.
      private def assignment_parts(node : Crystal::ASTNode) : {Crystal::ASTNode, Crystal::ASTNode}?
        case node
        when Crystal::Assign   then {node.target, node.value}
        when Crystal::OpAssign then {node.target, node.value}
        end
      end

      # # Size when `value` is an array literal, else nil.
      private def array_literal_size(value : Crystal::ASTNode) : Int32?
        literal = unwrap(value)
        literal.is_a?(Crystal::ArrayLiteral) ? plain_array_size(literal) : nil
      end

      # # The variable an assignment targets, or nil for slices and calls.
      private def assign_name(target : Crystal::ASTNode) : String?
        case target
        when Crystal::Var, Crystal::InstanceVar, Crystal::ClassVar
          target.name
        end
      end

      Rule.all << self.new
    end
  end
end

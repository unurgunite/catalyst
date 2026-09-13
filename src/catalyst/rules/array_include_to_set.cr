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
      # # Array literals below this size are not worth converting outside loops.
      SMALL_LITERAL_LIMIT = 8

      # # Block methods that imply repeated execution of their body.
      LOOP_BLOCK_METHODS = {
        "each", "each_with_index", "each_with_object",
        "times", "upto", "downto", "step", "loop",
      }

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
        @loop_depth = 0
        @array_sizes.clear
      end

      # # Check if node is an `includes?` call with exactly one argument.
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        track_assign(node)
        results = check_includes(node, context)
        track_enter(node)
        results
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        track_leave(node)
      end

      private def check_includes(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "includes?"
        return [] of Result unless node.args.size == 1
        return [] of Result unless receiver = node.obj

        unwrapped = unwrap(receiver)

        # Only receivers proven to be arrays are flagged: array literals
        # and variables assigned from array literals in this file.
        # Unknown receivers (params, call results, plain variables) stay
        # silent — suggesting `Set` for something already O(1) (e.g. a
        # `Set`) is worse than noise. Every non-array literal (Range with
        # O(1) lookup, numbers, String substring search, ...) is out too.
        size = array_receiver_size(unwrapped)
        return [] of Result if size.nil?
        return [] of Result if size < SMALL_LITERAL_LIMIT && @loop_depth == 0

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
          confidence: @loop_depth > 0 ? "medium" : "low",
        )]
      end

      # # Array size if receiver is proven to be an array, else nil.
      private def array_receiver_size(node : Crystal::ASTNode) : Int32?
        if node.is_a?(Crystal::ArrayLiteral)
          node.elements.size
        elsif node.is_a?(Crystal::Var) ||
              node.is_a?(Crystal::InstanceVar) ||
              node.is_a?(Crystal::ClassVar)
          @array_sizes[node.name]?
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
        case node
        when Crystal::Assign
          target, value = node.target, node.value
        when Crystal::OpAssign
          target, value = node.target, node.value
        else
          return
        end

        name = case target
               when Crystal::Var, Crystal::InstanceVar, Crystal::ClassVar
                 target.name
               else
                 return
               end

        literal = unwrap(value)
        if literal.is_a?(Crystal::ArrayLiteral)
          @array_sizes[name] = literal.elements.size
        else
          @array_sizes.delete(name)
        end
      end

      private def track_enter(node : Crystal::ASTNode) : Nil
        @loop_depth += 1 if loop_opener?(node)
      end

      private def track_leave(node : Crystal::ASTNode) : Nil
        @loop_depth -= 1 if loop_opener?(node)
      end

      private def loop_opener?(node : Crystal::ASTNode) : Bool
        case node
        when Crystal::While, Crystal::Until
          true
        when Crystal::Block
          call = node.call
          call.is_a?(Crystal::Call) && LOOP_BLOCK_METHODS.includes?(call.name)
        else
          false
        end
      end

      Rule.all << self.new
    end
  end
end

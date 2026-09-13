module Catalyst
  module Rules
    # # Detects `includes?` calls on arrays and suggests using a `Set`.
    ##
    # # `Array#includes?` is O(n) per call. When checking membership repeatedly
    # # (e.g. inside a loop), converting to a `Set` first makes each lookup O(1).
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
      end

      # # Check if node is an `includes?` call with exactly one argument.
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
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

        # Only array-literal and unknown (variable/call) receivers can
        # plausibly be arrays. Every other literal has either O(1) lookup
        # (Range), no meaningful `includes?` at all (numbers), or a
        # different semantic (String substring search) where `Set` makes
        # no sense.
        case unwrapped
        when Crystal::ArrayLiteral
          if unwrapped.elements.size < SMALL_LITERAL_LIMIT && @loop_depth == 0
            return [] of Result
          end
        when Crystal::RangeLiteral,
             Crystal::NumberLiteral,
             Crystal::StringLiteral,
             Crystal::SymbolLiteral,
             Crystal::CharLiteral,
             Crystal::RegexLiteral,
             Crystal::HashLiteral,
             Crystal::TupleLiteral,
             Crystal::NamedTupleLiteral,
             Crystal::NilLiteral,
             Crystal::BoolLiteral
          return [] of Result
        end

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

      # # Strip grouping parentheses: `(1..5)` parses as Expressions.
      private def unwrap(node : Crystal::ASTNode) : Crystal::ASTNode
        if node.is_a?(Crystal::Expressions) && node.expressions.size == 1
          node.expressions.first
        else
          node
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

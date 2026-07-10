module Catalyst
  module Rules
    # # Detects `map` + `sum` and suggests using `sum` with a block.
    ##
    # # `map` creates an intermediate array then `sum` iterates over it.
    # # Using `sum` with a block avoids the allocation and double iteration.
    class MapSumToDirectSum < Rule
      def id : String
        "CAT-002"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `sum` with a block instead of `map` followed by `sum`"
      end

      def auto_fixable? : Bool
        true
      end

      # # Check if node is `map{}.sum` or `map{}.sum(initial)`.
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = map_sum_call(node)
        return [] of Result unless call

        suggestion = if call.args.empty?
                       "sum { ... }"
                     else
                       "sum(...) { ... }"
                     end

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0
        line_text = context.line_text(line)
        fix = line_text.sub(/\.map(\s*\{.*\})\s*\.sum/) { ".sum#{$1}" }
        fix = fix.sub(/\.map(\s*\(&[^)]+\))\s*\.sum/) { ".sum#{$1}" }
        fix = nil if fix == line_text

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `sum` with a block instead of `map` followed by `sum`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `map{}.sum` with `#{suggestion}`",
          confidence: "high",
          fix_replacement: fix,
        )]
      end

      # # If node is `map{}.sum` or `map{}.sum(initial)`, return the outer call node.
      private def map_sum_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "sum"

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless target.name == "map"
        return nil unless target.block

        node
      end

      Rule.all << self.new
    end
  end
end

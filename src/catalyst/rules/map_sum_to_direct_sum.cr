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

        suggestion = call.args.empty? ? "sum { ... }" : "sum(...) { ... }"
        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `sum` with a block instead of `map` followed by `sum`",
          file: context.file,
          line: call.location.try(&.line_number) || 0,
          column: call.name_location.try(&.column_number) || 0,
          suggestion: "Replace `map{}.sum` with `#{suggestion}`",
          confidence: "high",
          fix_replacement: fix_for(call, context),
        )]
      end

      # # An initial value such as `.sum(0_i64)` lands *after* the block once
      # # the map is folded in, giving `sum { ... }(0_i64)` which does not
      # # parse. Moving it inside needs the block's text, so only the plain
      # # form is fixed.
      private def fix_for(call : Crystal::Call, context : Context) : String?
        return nil unless call.args.empty?

        sum_fix(context.line_text(call.location.try(&.line_number) || 0))
      end

      # # Folds `.map{...}.sum` into `.sum{...}`. `.*?` keeps the body from
      # # swallowing an enclosing block's closing brace.
      private def sum_fix(line : String) : String?
        once = line.sub(/\.map(\s*\{.*?\})\s*\.sum/) { ".sum#{$1}" }
        once = line.sub(/\.map(\s*\(&[^)]+\))\s*\.sum/) { ".sum#{$1}" } if once == line
        once == line ? nil : once
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

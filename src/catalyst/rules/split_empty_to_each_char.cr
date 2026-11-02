module Catalyst
  module Rules
    # # Flags the two ways of turning a String into per-character work that
    # # allocate an intermediate array: `split("")` and `chars.each`.
    # #
    # # These were two rules (CAT-035 and CAT-036) that suggested the same
    # # `each_char` rewrite and fired on the same intent. Keeping both meant
    # # two IDs for one finding, and code that hit one usually hit the other.
    # # CAT-036's number is retired rather than reused so an old `ignore`
    # # entry stays meaningful.
    class SplitEmptyToEachChar < Rule
      def id : String
        "CAT-035"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `each_char` instead of `split(\"\")` or `chars.each`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)

        if split_empty?(node)
          [result(node, context, "`split(\"\")`", "Replace `split(\"\")` with `each_char`")]
        elsif chars_each?(node)
          [result(node, context, "`chars.each`", "Replace `chars.each` with `each_char`")]
        else
          [] of Result
        end
      end

      private def split_empty?(node : Crystal::Call) : Bool
        return false unless node.name == "split"
        return false unless node.args.size == 1
        arg = node.args.first
        arg.is_a?(Crystal::StringLiteral) && arg.value == ""
      end

      private def chars_each?(node : Crystal::Call) : Bool
        return false unless node.name == "each"
        target = node.obj
        return false unless target.is_a?(Crystal::Call)
        return false unless target.name == "chars"
        return false unless target.args.empty?
        target.block.nil?
      end

      private def result(node : Crystal::Call, context : Context, shape : String, suggestion : String) : Result
        Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `each_char` instead of #{shape} to avoid an intermediate array allocation",
          file: context.file,
          line: node.location.try(&.line_number) || 0,
          column: node.name_location.try(&.column_number) || 0,
          suggestion: suggestion,
          confidence: "high",
        )
      end

      Rule.all << self.new
    end
  end
end

module Catalyst
  module Rules
    # # Detects `reverse.each` and suggests `reverse_each`.
    ##
    # # `Array#reverse` creates a new reversed array.
    # # `Array#reverse_each` iterates backwards without allocation.
    class ReverseEachToReverseEach < Rule
      def id : String
        "CAT-007"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `reverse_each` instead of `reverse.each`"
      end

      def auto_fixable? : Bool
        true
      end

      # # Check if node is `reverse.each` (no args, no block on reverse).
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = reverse_each_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0
        line_text = context.line_text(line)
        fix = line_text.gsub(".reverse.each", ".reverse_each")

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `reverse_each` instead of `reverse.each`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `reverse.each` with `reverse_each`",
          confidence: "high",
          fix_replacement: fix,
        )]
      end

      # # If node is `reverse.each`, return the outer call node.
      private def reverse_each_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "each"
        return nil unless node.args.empty?
        return nil unless (target = node.obj).is_a?(Crystal::Call)
        return nil unless target.name == "reverse"
        return nil unless target.args.empty?
        return nil unless target.block.nil?
        node
      end

      Rule.all << self.new
    end
  end
end

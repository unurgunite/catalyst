module Catalyst
  module Rules
    # # Detects `keys.each` and suggests `each_key`.
    ##
    # # `Hash#keys` allocates an intermediate array of keys then iterates.
    # # `Hash#each_key` iterates directly without allocation.
    class HashKeysEachToEachKey < Rule
      def id : String
        "CAT-006"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `each_key` instead of `keys.each`"
      end

      # # Check if node is `hash.keys.each`.
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = keys_each_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `each_key` instead of `keys.each`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `keys.each` with `each_key`",
          confidence: "high"
        )]
      end

      # # If node is `x.keys.each`, return the outer `each` call node.
      private def keys_each_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "each"
        return nil unless node.args.empty?

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless target.name == "keys"
        return nil unless target.args.empty?
        return nil unless target.block.nil?

        node
      end

      Rule.all << self.new
    end
  end
end

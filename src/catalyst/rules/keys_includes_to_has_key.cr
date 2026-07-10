module Catalyst
  module Rules
    class KeysIncludesToHasKey < Rule
      def id : String
        "CAT-030"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `has_key?` instead of `keys.includes?`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = keys_includes_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `has_key?` instead of `keys.includes?`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `keys.includes?` with `has_key?`",
          confidence: "high"
        )]
      end

      private def keys_includes_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "includes?"
        return nil unless node.args.size == 1

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

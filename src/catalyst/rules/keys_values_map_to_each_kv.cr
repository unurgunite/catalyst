module Catalyst
  module Rules
    class KeysValuesMapToEachKv < Rule
      def id : String
        "CAT-024"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `each_key.map`/`each_value.map` instead of `keys.map`/`values.map`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = keys_values_map_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        target = call.obj
        method = target.is_a?(Crystal::Call) ? target.name : ""

        replacement = method == "keys" ? "each_key" : "each_value"

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `#{replacement}.map` instead of `#{method}.map`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `#{method}.map` with `#{replacement}.map`",
          confidence: "high"
        )]
      end

      private def keys_values_map_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "map"
        return nil unless node.args.empty?

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless %w(keys values).includes?(target.name)
        return nil unless target.args.empty?
        return nil unless target.block.nil?

        node
      end

      Rule.all << self.new
    end
  end
end

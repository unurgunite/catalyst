module Catalyst
  module Rules
    class EachWithIndexMapToMapWithIndex < Rule
      def id : String
        "CAT-034"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `map_with_index` instead of `each_with_index` followed by `map`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = each_with_index_map_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `map_with_index` instead of `each_with_index` followed by `map`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `each_with_index.map` with `map_with_index`",
          confidence: "medium",
        )]
      end

      private def each_with_index_map_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "map"

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless target.name == "each_with_index"
        return nil unless target.args.empty?
        return nil unless target.block.nil?

        node
      end

      Rule.all << self.new
    end
  end
end

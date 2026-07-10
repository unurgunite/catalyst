module Catalyst
  module Rules
    class SelectMapToFilterMap < Rule
      def id : String
        "CAT-033"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `filter_map` instead of `select` followed by `map`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = select_map_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `filter_map` instead of `select` followed by `map`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `select{}.map{}` with `filter_map{}`",
          confidence: "medium",
        )]
      end

      private def select_map_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "map"

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless target.name == "select"

        node
      end

      Rule.all << self.new
    end
  end
end

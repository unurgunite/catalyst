module Catalyst
  module Rules
    class ValuesEachToEachValue < Rule
      def id : String
        "CAT-021"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `each_value` instead of `values.each`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = values_each_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `each_value` instead of `values.each`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `values.each` with `each_value`",
          confidence: "high"
        )]
      end

      private def values_each_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "each"
        return nil unless node.args.empty?

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless target.name == "values"
        return nil unless target.args.empty?
        return nil unless target.block.nil?

        node
      end

      Rule.all << self.new
    end
  end
end

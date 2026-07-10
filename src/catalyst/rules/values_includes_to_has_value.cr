module Catalyst
  module Rules
    class ValuesIncludesToHasValue < Rule
      def id : String
        "CAT-031"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `has_value?` instead of `values.includes?`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = values_includes_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `has_value?` instead of `values.includes?`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `values.includes?` with `has_value?`",
          confidence: "high"
        )]
      end

      private def values_includes_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "includes?"
        return nil unless node.args.size == 1

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

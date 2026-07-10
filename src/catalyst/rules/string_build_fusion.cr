module Catalyst
  module Rules
    class StringBuildFusion < Rule
      def id : String
        "CAT-040"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `String.build` instead of consecutive string concatenations"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "+"
        return [] of Result unless node.obj.is_a?(Crystal::StringLiteral)

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `String.build` instead of consecutive `String#+` concatenations",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Use `String.build` block to accumulate string fragments",
          confidence: "low"
        )]
      end

      Rule.all << self.new
    end
  end
end

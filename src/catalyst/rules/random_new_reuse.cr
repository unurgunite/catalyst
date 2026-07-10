module Catalyst
  module Rules
    class RandomNewReuse < Rule
      def id : String
        "CAT-043"
      end

      def severity : String
        "info"
      end

      def description : String
        "Reuse `Random.new` instance instead of creating each call"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "new"

        obj = node.obj
        return [] of Result unless obj.is_a?(Crystal::Path)
        return [] of Result unless obj.names == ["Random"]

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Reuse `Random.new` instance instead of creating each call",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Store `Random.new` in a constant: `RAND = Random.new`",
          confidence: "medium",
        )]
      end

      Rule.all << self.new
    end
  end
end

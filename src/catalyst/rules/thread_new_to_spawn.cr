module Catalyst
  module Rules
    class ThreadNewToSpawn < Rule
      def id : String
        "CAT-049"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `spawn` instead of `Thread.new`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "new"

        obj = node.obj
        return [] of Result unless obj.is_a?(Crystal::Path)
        return [] of Result unless obj.names == ["Thread"]

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `spawn` instead of `Thread.new`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `Thread.new { ... }` with `spawn { ... }`",
          confidence: "high",
        )]
      end

      Rule.all << self.new
    end
  end
end

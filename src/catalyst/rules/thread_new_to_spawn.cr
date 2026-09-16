module Catalyst
  module Rules
    class ThreadNewToSpawn < Rule
      def id : String
        "CAT-049"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `spawn` instead of `Thread.new` (only if a fiber, not a thread, is really needed)"
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
          message: "Use `spawn` instead of `Thread.new` (only if a fiber, not a thread, is really needed)",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `Thread.new { ... }` with `spawn { ... }` only when OS-thread semantics (parallelism, blocking calls, thread-local state) are not required",
          confidence: "low",
        )]
      end

      Rule.all << self.new
    end
  end
end

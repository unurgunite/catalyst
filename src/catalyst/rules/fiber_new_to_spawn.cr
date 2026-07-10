module Catalyst
  module Rules
    class FiberNewToSpawn < Rule
      def id : String
        "CAT-050"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `spawn` instead of `Fiber.new { ... }.resume`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "resume"

        obj = node.obj
        return [] of Result unless obj.is_a?(Crystal::Call)
        return [] of Result unless obj.name == "new"

        inner_obj = obj.obj
        return [] of Result unless inner_obj.is_a?(Crystal::Path)
        return [] of Result unless inner_obj.names == ["Fiber"]

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `spawn` instead of `Fiber.new { ... }.resume`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `Fiber.new { ... }.resume` with `spawn { ... }`",
          confidence: "high",
        )]
      end

      Rule.all << self.new
    end
  end
end

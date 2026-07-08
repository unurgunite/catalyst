module Catalyst
  module Rules
    class RegexNewToConstant < Rule
      def id : String
        "CAT-019"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Hoist `Regex.new` out of loop to a constant"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "new" || node.name == "compile"
        return [] of Result unless (obj = node.obj).is_a?(Crystal::Path)
        return [] of Result unless obj.names == ["Regex"]

        line = node.location.try(&.line_number) || 0
        source_line = context.line_text(line)
        return [] of Result if source_line =~ /^\s*[A-Z]\w*\s*=/

        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Hoist `Regex.#{node.name}` out of loop to a constant",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Define `RE = Regex.#{node.name}(...)` outside the loop and reuse `RE`",
          confidence: "high"
        )]
      end

      Rule.all << self.new
    end
  end
end

module Catalyst
  module Rules
    class RegexNewInMethod < Rule
      def id : String
        "CAT-039"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use class constant for `Regex.new` inside method"
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
          message: "Use class constant for `Regex.#{node.name}` instead of creating inside method",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Define `RE = Regex.#{node.name}(...)` as a constant and reuse",
          confidence: "high"
        )]
      end

      Rule.all << self.new
    end
  end
end

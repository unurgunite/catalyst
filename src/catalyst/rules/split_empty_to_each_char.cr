module Catalyst
  module Rules
    class SplitEmptyToEachChar < Rule
      def id : String
        "CAT-035"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `each_char` instead of `split(\"\")`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = split_empty_candidate(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `each_char` instead of `split(\"\")` to avoid array allocation",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `split(\"\")` with `each_char`",
          confidence: "high",
        )]
      end

      private def split_empty_candidate(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "split"
        return nil unless node.args.size == 1

        arg = node.args.first
        return nil unless arg.is_a?(Crystal::StringLiteral)
        return nil unless arg.value == ""

        node
      end

      Rule.all << self.new
    end
  end
end

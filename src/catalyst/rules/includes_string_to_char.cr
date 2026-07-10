module Catalyst
  module Rules
    class IncludesStringToChar < Rule
      def id : String
        "CAT-023"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use char literal instead of string literal in `includes?`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = includes_char_candidate(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        arg = call.args.first.as(Crystal::StringLiteral)
        char = arg.value

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use char literal `'#{char}'` instead of string literal `\"#{char}\"` in `includes?`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `#{char}` with `'#{char}'`",
          confidence: "high"
        )]
      end

      private def includes_char_candidate(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "includes?"
        return nil unless node.args.size == 1

        arg = node.args.first
        return nil unless arg.is_a?(Crystal::StringLiteral)
        return nil unless arg.value.size == 1

        node
      end

      Rule.all << self.new
    end
  end
end

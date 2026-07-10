module Catalyst
  module Rules
    class MatchToMatches < Rule
      def id : String
        "CAT-018"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `matches?` instead of `match` or `=~` for boolean context"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = match_or_match_operator_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        method_name = call.name == "=~" ? "=~" : "match"
        suggestion = call.name == "=~" ? "Use `matches?` instead of `=~`" : "Use `matches?` instead of `match`"

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `String#matches?` instead of `String##{method_name}`",
          file: context.file,
          line: line,
          column: col,
          suggestion: suggestion,
          confidence: "high",
        )]
      end

      private def match_or_match_operator_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)

        if node.name == "match"
          return nil unless node.obj
          return nil unless node.block.nil?
          node
        elsif node.name == "=~"
          node
        else
          nil
        end
      end

      Rule.all << self.new
    end
  end
end

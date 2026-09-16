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
        "Use `matches?` instead of `match` for boolean context"
      end

      def auto_fixable? : Bool
        true
      end

      def initialize
        @ancestors = [] of Crystal::ASTNode
      end

      def setup(file_path : String, source : String) : Nil
        @ancestors.clear
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        parent = @ancestors.last?
        @ancestors << node
        call = match_call(node)
        return [] of Result unless call
        return [] of Result unless boolean_parent?(parent)

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `String#matches?` instead of `String#match`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Use `matches?` instead of `match`",
          confidence: "high",
        )]
      end

      private def match_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "match"
        return nil unless node.obj
        return nil unless node.block.nil?
        # NOTE: `=~` is deliberately NOT handled here. It returns
        # `Int32 | Nil` (match position), not `Bool`, so suggesting
        # `matches?` would change the program's type — e.g. `i = s =~ /re/`.
        node
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        # Pop only our own push: some nodes (e.g. the root `Expressions`)
        # are never passed through `check`, so pop unconditionally would
        # misalign the stack.
        if last = @ancestors.last?
          @ancestors.pop if last.same?(node)
        end
      end

      # True when the `match` result is consumed as boolean. Anything else
      # (`m = s.match(/re/)`, bare calls, method args) may need the
      # `MatchData` itself and stays silent — trading recall for precision.
      private def boolean_parent?(parent : Crystal::ASTNode?) : Bool
        case parent
        when Crystal::If, Crystal::Unless,
             Crystal::While, Crystal::Until,
             Crystal::Not, Crystal::And, Crystal::Or
          true
        else
          false
        end
      end

      Rule.all << self.new
    end
  end
end

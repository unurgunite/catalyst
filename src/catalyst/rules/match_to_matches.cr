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
        @string_vars = Set(String).new
      end

      def setup(file_path : String, source : String) : Nil
        @ancestors.clear
        @string_vars.clear
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        parent = @ancestors.last?
        @ancestors << node
        track_assign(node)
        call = match_call(node)
        return [] of Result unless call
        # `matches?` only exists on String. A custom object or a LibPCRE2
        # binding with a `match` method would not compile after the swap.
        return [] of Result unless string_receiver?(call.obj)
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
          fix_replacement: match_fix(call, context.line_text(line)),
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

      # Swap `.match(` for `.matches?(` — the signatures align
      # (`pattern, pos = 0`). Only when the line holds a single `.match(`
      # call; multi-call lines get a finding without a fix.
      private def match_fix(call : Crystal::Call, line_text : String) : String?
        return nil unless line_text.scan(".match(").size == 1
        fixed = line_text.sub(".match(", ".matches?(")
        fixed == line_text ? nil : fixed
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

      # True when the receiver is recognisably a String.
      private def string_receiver?(obj : Crystal::ASTNode?) : Bool
        case obj
        when Crystal::StringLiteral, Crystal::StringInterpolation
          true
        when Crystal::Var
          @string_vars.includes?(obj.name)
        else
          false
        end
      end

      private def track_assign(node : Crystal::ASTNode) : Nil
        return unless node.is_a?(Crystal::Assign)
        target = node.target
        return unless target.is_a?(Crystal::Var)
        value = node.value
        if value.is_a?(Crystal::StringLiteral) || value.is_a?(Crystal::StringInterpolation)
          @string_vars << target.name
        elsif !value.is_a?(Crystal::Call)
          @string_vars.delete(target.name)
        end
      end

      Rule.all << self.new
    end
  end
end

module Catalyst
  module Rules
    # # Flags `str.includes?("c")` where a one-character string is passed:
    # # `String#includes?(Char)` skips the substring search.
    # #
    # # The rule only fires when the receiver is known to be a String — a
    # # string literal, an interpolation, or a variable assigned a string
    # # literal in the same file. `Array(String)#includes?("c")` also takes a
    # # one-character string, and suggesting `'c'` there changes the type, so
    # # an unknown receiver is left alone. Without that guard the rule fired
    # # on configuration arrays (`cfg["keys"].includes? "*"`) and offered a
    # # rewrite that would not compile.
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

      def initialize
        # # Names of variables assigned a string literal in this file.
        @string_vars = Set(String).new
      end

      def auto_fixable? : Bool
        true
      end

      def setup(file_path : String, source : String) : Nil
        @string_vars.clear
        super
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        track_assign(node)
        call = includes_char_candidate(node)
        return [] of Result unless call
        return [] of Result unless string_receiver?(call.obj)

        arg = call.args.first.as(Crystal::StringLiteral)
        char = arg.value

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use char literal `'#{char}'` instead of string literal `\"#{char}\"` in `includes?`",
          file: context.file,
          line: call.location.try(&.line_number) || 0,
          column: call.name_location.try(&.column_number) || 0,
          suggestion: "Replace `#{"\"#{char}\""}` with `'#{char}'`",
          confidence: "medium",
          fix_replacement: fix_for(call, char, context)
        )]
      end

      # # Replaces the one-character string literal this call was given with a
      # # char literal. The position comes from the AST rather than a text
      # # pattern, because the literal is masked out as a string when searching
      # # for code, and because a line may hold several of them.
      private def fix_for(call : Crystal::Call, char : String, context : Context) : String?
        return nil unless call.args.size == 1
        line = context.line_text(call.location.try(&.line_number) || 0)
        start = arg_column(call)
        return nil unless start
        width = char.size + 2
        return nil unless line[start - 1, width]? == %("#{char}")

        line[0...(start - 1)] + "'#{char}'" + line[(start - 1 + width)..]
      end

      # # 1-based column of the first argument's opening quote.
      private def arg_column(call : Crystal::Call) : Int32?
        arg = call.args.first
        return nil unless arg.is_a?(Crystal::StringLiteral)
        arg.location.try(&.column_number)
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

      # # True when the receiver is recognisably a String.
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
          # A variable reassigned to something else is no longer known to be
          # a String.
          @string_vars.delete(target.name)
        end
      end

      Rule.all << self.new
    end
  end
end

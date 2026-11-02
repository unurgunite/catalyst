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
          confidence: "medium"
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

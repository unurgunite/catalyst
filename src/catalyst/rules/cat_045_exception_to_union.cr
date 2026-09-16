module Catalyst
  module Rules
    class ExceptionToUnion < Rule
      @inside_def : Bool = false
      # # Bang methods (`validate!`, `fetch!`) raise by naming contract —
      # # flagging them contradicts Crystal idiom, so they stay silent.
      # # `initialize` is silent too: a union return would break the
      # # constructor contract.
      @skip_def : Bool = false

      def id : String
        "CAT-045"
      end

      def severity : String
        "info"
      end

      def description : String
        "Raise Exception for expected failure, consider returning Union(T, Nil)"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        if node.is_a?(Crystal::Def)
          @inside_def = true
          @skip_def = node.name.ends_with?("!") || node.name == "initialize"
        end

        if @inside_def && !@skip_def && node.is_a?(Crystal::Call) && node.name == "raise" && node.args.size >= 1
          line = node.location.try(&.line_number) || 0
          column = node.location.try(&.column_number) || 0
          [Result.new(
            rule_id: id,
            severity: severity,
            message: "Raise Exception for expected failure, consider returning a Union(T, Nil) type",
            file: context.file,
            line: line,
            column: column,
            suggestion: "Replace with returning nil and use Union(SuccessType, Nil) return type",
            confidence: confidence
          )]
        else
          [] of Result
        end
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        if node.is_a?(Crystal::Def)
          @inside_def = false
          @skip_def = false
        end
      end

      Rule.all << self.new
    end
  end
end

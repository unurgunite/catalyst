module Catalyst
  module Rules
    class ExceptionToUnion < Rule
      @inside_def : Bool = false

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
        end

        if @inside_def && node.is_a?(Crystal::Call) && node.name == "raise" && node.args.size >= 1
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
        end
      end

      Rule.all << self.new
    end
  end
end

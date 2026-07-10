module Catalyst
  module Rules
    class ReverseReverseNoop < Rule
      def id : String
        "CAT-046"
      end

      def severity : String
        "info"
      end

      def description : String
        "Remove redundant reverse.reverse chain"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "reverse"
        return [] of Result unless node.args.empty?
        return [] of Result unless (obj = node.obj).is_a?(Crystal::Call)
        return [] of Result unless obj.name == "reverse"
        return [] of Result unless obj.args.empty?

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Remove redundant reverse.reverse chain",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Remove `.reverse.reverse`; it returns the original collection unchanged",
          confidence: "high"
        )]
      end

      Rule.all << self.new
    end
  end
end

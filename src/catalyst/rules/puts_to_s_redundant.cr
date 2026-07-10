module Catalyst
  module Rules
    class PutsToSRedundant < Rule
      OUTPUT_METHODS = {"puts", "print", "write"}

      def id : String
        "CAT-048"
      end

      def severity : String
        "info"
      end

      def description : String
        "Remove redundant .to_s in puts/print/STDOUT calls"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless OUTPUT_METHODS.includes?(node.name)
        return [] of Result unless node.args.size == 1
        return [] of Result unless (arg = node.args.first).is_a?(Crystal::Call)
        return [] of Result unless arg.name == "to_s"
        return [] of Result unless arg.args.empty?

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Remove redundant `#to_s` in `#{node.name}` call",
          file: context.file,
          line: line,
          column: col,
          suggestion: "`#{node.name}` already calls `to_s` on its arguments",
          confidence: "high"
        )]
      end

      Rule.all << self.new
    end
  end
end

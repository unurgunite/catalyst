module Catalyst
  module Rules
    class UpcaseDowncaseNoop < Rule
      PAIRS = {"upcase" => "downcase", "downcase" => "upcase"}

      def id : String
        "CAT-047"
      end

      def severity : String
        "info"
      end

      def description : String
        "Remove redundant upcase.downcase chain"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless target = PAIRS[node.name]?
        return [] of Result unless node.args.empty?
        return [] of Result unless (obj = node.obj).is_a?(Crystal::Call)
        return [] of Result unless obj.name == target
        return [] of Result unless obj.args.empty?

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        chain = "#{target}.#{node.name}"

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Remove redundant `#{chain}` chain",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Remove `.#{chain}`; it cancels itself out",
          confidence: "high"
        )]
      end

      Rule.all << self.new
    end
  end
end

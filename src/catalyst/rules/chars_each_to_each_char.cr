module Catalyst
  module Rules
    class CharsEachToEachChar < Rule
      def id : String
        "CAT-036"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `each_char` instead of `chars.each`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = chars_each_candidate(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `each_char` instead of `chars.each` to avoid intermediate array",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `chars.each` with `each_char`",
          confidence: "high",
        )]
      end

      private def chars_each_candidate(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "each"

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless target.name == "chars"
        return nil unless target.args.empty?
        return nil unless target.block.nil?

        node
      end

      Rule.all << self.new
    end
  end
end

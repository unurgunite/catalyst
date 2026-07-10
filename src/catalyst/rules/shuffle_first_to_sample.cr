module Catalyst
  module Rules
    class ShuffleFirstToSample < Rule
      def id : String
        "CAT-022"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `sample` instead of `shuffle.first`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = shuffle_first_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `sample` instead of `shuffle.first`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `shuffle.first` with `sample`",
          confidence: "high"
        )]
      end

      private def shuffle_first_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "first"
        return nil unless node.args.empty?

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless target.name == "shuffle"
        return nil unless target.args.empty?
        return nil unless target.block.nil?

        node
      end

      Rule.all << self.new
    end
  end
end

module Catalyst
  module Rules
    class SplitFirstToSplitLimit < Rule
      def id : String
        "CAT-032"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `split` with limit argument instead of `split.first` or `split[0]`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = split_first_candidate(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `split` with limit argument to avoid allocating full array",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Add a limit argument: `split(delimiter, 2)`",
          confidence: "high",
        )]
      end

      private def split_first_candidate(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "[]"
        return nil unless node.args.size == 1

        arg = node.args.first
        return nil unless arg.is_a?(Crystal::NumberLiteral)
        return nil unless arg.value == "0"

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless target.name == "split"
        return nil unless target.args.size == 1
        return nil unless target.block.nil?

        node
      end

      Rule.all << self.new
    end
  end
end

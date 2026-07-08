module Catalyst
  module Rules
    # # Detects `downcase` + `==` / `!=` and suggests `compare(case_insensitive: true)`.
    ##
    # # `str1.downcase == str2.downcase` allocates two downcased strings.
    # # `str1.compare(str2, case_insensitive: true) == 0` compares case-insensitively without allocation.
    class DowncaseCompareToCasecmp < Rule
      def id : String
        "CAT-018"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `compare(case_insensitive: true)` for case-insensitive comparison instead of `downcase` + `==`"
      end

      # # Check if node is `str.downcase == ...` or `str.downcase != ...`.
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = downcase_compare_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `compare(case_insensitive: true)` for case-insensitive comparison instead of `downcase` + `#{call.name}`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Use `compare(case_insensitive: true)` instead of `downcase` + `#{call.name}`",
          confidence: "high",
        )]
      end

      # # If node is `str.downcase == ...` or `str.downcase != ...`, return the outer call node.
      private def downcase_compare_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "==" || node.name == "!="
        return nil unless node.args.size == 1

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless target.name == "downcase"
        return nil unless target.args.empty?
        return nil unless target.block.nil?

        node
      end

      Rule.all << self.new
    end
  end
end

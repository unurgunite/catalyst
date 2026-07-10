module Catalyst
  module Rules
    class TempfileLeak < Rule
      def id : String
        "CAT-027"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Tempfile resource leak — use block form or ensure close"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = tempfile_new_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Tempfile resource leak — use block form or ensure `close` is called",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Use block form: `Tempfile.new(name) { |f| ... }` or ensure `tempfile.close`",
          confidence: "high"
        )]
      end

      private def tempfile_new_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "new"
        return nil unless (obj = node.obj).is_a?(Crystal::Path)
        return nil unless obj.names == %w[Tempfile]
        return nil unless node.block.nil?
        node
      end

      Rule.all << self.new
    end
  end
end

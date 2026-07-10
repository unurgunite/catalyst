module Catalyst
  module Rules
    class DbOpenLeak < Rule
      def id : String
        "CAT-029"
      end

      def severity : String
        "warning"
      end

      def description : String
        "DB.open resource leak — use block form to auto-close"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = db_open_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "DB.open resource leak — use block form to auto-close connection",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Use block form: `DB.open(url) { |db| ... }`",
          confidence: "high"
        )]
      end

      private def db_open_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "open"
        return nil unless (obj = node.obj).is_a?(Crystal::Path)
        return nil unless obj.names == %w[DB]
        return nil unless node.block.nil?
        node
      end

      Rule.all << self.new
    end
  end
end

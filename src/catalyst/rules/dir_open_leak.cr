module Catalyst
  module Rules
    class DirOpenLeak < Rule
      def id : String
        "CAT-026"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Dir.open resource leak — use block form to auto-close"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = dir_open_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Dir.open resource leak — use block form to auto-close directory",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Use block form: `Dir.open(path) { |d| ... }`",
          confidence: "high"
        )]
      end

      private def dir_open_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "open"
        return nil unless (obj = node.obj).is_a?(Crystal::Path)
        return nil unless obj.names == %w[Dir]
        return nil unless node.block.nil?
        node
      end

      Rule.all << self.new
    end
  end
end

module Catalyst
  module Rules
    class FileOpenLeak < Rule
      def id : String
        "CAT-025"
      end

      def severity : String
        "warning"
      end

      def description : String
        "File.open resource leak — use block form to auto-close"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = file_open_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "File.open resource leak — use block form to auto-close file",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Use block form: `File.open(path) { |f| ... }`",
          confidence: "high"
        )]
      end

      private def file_open_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "open"
        return nil unless (obj = node.obj).is_a?(Crystal::Path)
        return nil unless obj.names == %w[File]
        return nil unless node.block.nil?
        node
      end

      Rule.all << self.new
    end
  end
end

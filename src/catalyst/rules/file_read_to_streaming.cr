module Catalyst
  module Rules
    class FileReadToStreaming < Rule
      FILE_METHODS = {"read", "read_lines"}

      def id : String
        "CAT-014"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use streaming instead of reading entire file at once"
      end

      def auto_fixable? : Bool
        true
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = file_read_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use streaming (`File.open`) instead of `File.#{call.name}` for large files",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `File.#{call.name}` with `File.open` for streaming",
          confidence: "medium",
        )]
      end

      private def file_read_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name.in?(FILE_METHODS)

        target = node.obj
        return nil unless target.is_a?(Crystal::Path)
        return nil unless target.names == ["File"]

        node
      end

      Rule.all << self.new
    end
  end
end

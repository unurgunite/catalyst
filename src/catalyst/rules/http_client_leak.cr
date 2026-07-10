module Catalyst
  module Rules
    class HttpClientLeak < Rule
      def id : String
        "CAT-028"
      end

      def severity : String
        "warning"
      end

      def description : String
        "HTTP::Client resource leak — use block form or ensure close"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = http_client_new_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "HTTP::Client resource leak — use block form or ensure `close` is called",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Use block form: `HTTP::Client.new(url) { |c| ... }` or ensure `client.close`",
          confidence: "high"
        )]
      end

      private def http_client_new_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "new"
        return nil unless (obj = node.obj).is_a?(Crystal::Path)
        return nil unless obj.names == %w[HTTP Client]
        return nil unless node.block.nil?
        node
      end

      Rule.all << self.new
    end
  end
end

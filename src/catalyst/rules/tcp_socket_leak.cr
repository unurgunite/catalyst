module Catalyst
  module Rules
    class TcpSocketLeak < Rule
      def id : String
        "CAT-013"
      end

      def severity : String
        "error"
      end

      def description : String
        "TCPSocket resource leak — ensure socket is closed"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = tcp_socket_new_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "TCPSocket resource leak — ensure socket is closed with `close` or use block form",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Wrap socket usage in `ensure` block: `socket.close` or use `TCPSocket.new { |s| ... }`",
          confidence: "high"
        )]
      end

      private def tcp_socket_new_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "new"
        return nil unless (obj = node.obj).is_a?(Crystal::Path)
        return nil unless obj.names == %w[TCPSocket]
        return nil unless node.block.nil?
        node
      end

      Rule.all << self.new
    end
  end
end

module Catalyst
  module Rules
    # # CAT-013: TCPSocket resource leak — ensure socket is closed with `close` or use block form
    class TcpSocketLeak < ResourceLeakRule
      def id : String
        "CAT-013"
      end

      def severity : String
        "error"
      end

      def description : String
        "TCPSocket resource leak — ensure socket is closed with `close` or use block form"
      end

      def acquire_method : String
        "new"
      end

      def resource_type : String
        "TCPSocket"
      end

      def message : String
        "TCPSocket resource leak — ensure socket is closed with `close` or use block form"
      end

      def suggestion : String
        "Wrap socket usage in `ensure` block: `socket.close` or use `TCPSocket.new { |s| ... }`"
      end

      Rule.all << self.new
    end
  end
end

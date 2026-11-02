module Catalyst
  module Rules
    # # CAT-028: HTTP::Client resource leak — use block form or ensure `close` is called
    class HttpClientLeak < ResourceLeakRule
      def id : String
        "CAT-028"
      end

      def severity : String
        "warning"
      end

      def description : String
        "HTTP::Client resource leak — use block form or ensure `close` is called"
      end

      def acquire_method : String
        "new"
      end

      def resource_type : String
        "HTTP::Client"
      end

      def message : String
        "HTTP::Client resource leak — use block form or ensure `close` is called"
      end

      def suggestion : String
        "Use block form: `HTTP::Client.new(url) { |c| ... }` or ensure `client.close`"
      end

      Rule.all << self.new
    end
  end
end

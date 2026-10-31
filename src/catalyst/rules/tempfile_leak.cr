module Catalyst
  module Rules
    # # CAT-027: Tempfile resource leak — use block form or ensure `close` is called
    class TempfileLeak < ResourceLeakRule
      def id : String
        "CAT-027"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Tempfile resource leak — use block form or ensure `close` is called"
      end

      def acquire_method : String
        "new"
      end

      def resource_type : String
        "Tempfile"
      end

      def message : String
        "Tempfile resource leak — use block form or ensure `close` is called"
      end

      def suggestion : String
        "Use block form: `Tempfile.new(name) { |f| ... }` or ensure `tempfile.close`"
      end

      Rule.all << self.new
    end
  end
end

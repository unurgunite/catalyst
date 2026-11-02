module Catalyst
  module Rules
    # # CAT-029: DB.open resource leak — use block form to auto-close
    class DbOpenLeak < ResourceLeakRule
      def id : String
        "CAT-029"
      end

      def severity : String
        "warning"
      end

      def description : String
        "DB.open resource leak — use block form to auto-close"
      end

      def acquire_method : String
        "open"
      end

      def resource_type : String
        "DB"
      end

      def message : String
        "DB.open resource leak — use block form to auto-close connection"
      end

      def suggestion : String
        "Use block form: `DB.open(url) { |db| ... }`"
      end

      Rule.all << self.new
    end
  end
end

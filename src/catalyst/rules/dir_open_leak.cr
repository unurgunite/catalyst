module Catalyst
  module Rules
    # # CAT-026: Dir.open resource leak — use block form to auto-close
    class DirOpenLeak < ResourceLeakRule
      def id : String
        "CAT-026"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Dir.open resource leak — use block form to auto-close"
      end

      def acquire_method : String
        "open"
      end

      def resource_type : String
        "Dir"
      end

      def message : String
        "Dir.open resource leak — use block form to auto-close directory"
      end

      def suggestion : String
        "Use block form: `Dir.open(path) { |d| ... }`"
      end

      Rule.all << self.new
    end
  end
end

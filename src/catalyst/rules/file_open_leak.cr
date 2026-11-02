module Catalyst
  module Rules
    # # CAT-025: File.open resource leak — use block form to auto-close
    class FileOpenLeak < ResourceLeakRule
      def id : String
        "CAT-025"
      end

      def severity : String
        "info"
      end

      def description : String
        "File.open resource leak — use block form to auto-close"
      end

      def acquire_method : String
        "open"
      end

      def resource_type : String
        "File"
      end

      def message : String
        "File.open resource leak — use block form to auto-close file"
      end

      def suggestion : String
        "Use block form: `File.open(path) { |f| ... }`"
      end

      # # No block form exists for this constructor and callers frequently
      # # close the handle on another line, so the shape alone is weak evidence.
      def confidence : String
        "low"
      end

      Rule.all << self.new
    end
  end
end

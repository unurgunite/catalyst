module Catalyst
  module Rules
    class MultiPassGsub < Rule
      @counted : Array(Crystal::ASTNode)

      def initialize
        @counted = [] of Crystal::ASTNode
      end

      def id : String
        "CAT-011"
      end

      def severity : String
        "info"
      end

      def description : String
        "Combine multiple `gsub` calls into a single pass"
      end

      def setup(file_path : String, source : String)
        @counted.clear
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "gsub"

        receiver = node.obj
        return [] of Result unless receiver.is_a?(Crystal::Call)
        return [] of Result unless receiver.name == "gsub"
        return [] of Result if counted_in_chain?(node)

        chain = collect_chain(node)
        @counted.concat(chain)

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Combine multiple `gsub` calls into a single pass",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Combine multiple `gsub` calls into a single `gsub` with a hash argument",
          confidence: "medium",
        )]
      end

      private def counted_in_chain?(node : Crystal::Call) : Bool
        current = node
        while current.is_a?(Crystal::Call) && current.name == "gsub"
          return true if @counted.any?(&.same?(current))
          current = current.obj
        end
        false
      end

      private def collect_chain(node : Crystal::Call) : Array(Crystal::ASTNode)
        chain = [] of Crystal::ASTNode
        current = node
        while current.is_a?(Crystal::Call) && current.name == "gsub"
          chain << current
          current = current.obj
        end
        chain
      end

      Rule.all << self.new
    end
  end
end

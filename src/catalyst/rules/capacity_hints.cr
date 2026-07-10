module Catalyst
  module Rules
    class CapacityHints < Rule
      COLLECTION_TYPES = {"Array", "Hash"}

      def id : String
        "CAT-038"
      end

      def severity : String
        "info"
      end

      def description : String
        "Pre-size collections with capacity hints when size is known"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "new"
        return [] of Result unless node.args.empty?

        obj = node.obj
        return [] of Result unless obj.is_a?(Crystal::Generic)
        return [] of Result unless obj.name.is_a?(Crystal::Path)

        names = obj.name.as(Crystal::Path).names
        return [] of Result unless names.size == 1 && names.first.in?(COLLECTION_TYPES)

        collection = names.first
        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Pre-size `#{collection}` with capacity hint via `.new(capacity)` when size is known",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Use `#{collection}(Type).new(expected_size)` to avoid reallocations",
          confidence: "medium",
        )]
      end

      Rule.all << self.new
    end
  end
end

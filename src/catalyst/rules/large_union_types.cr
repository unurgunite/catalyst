module Catalyst
  module Rules
    class LargeUnionTypes < Rule
      THRESHOLD = 4

      def id : String
        "CAT-016"
      end

      def severity : String
        "info"
      end

      def description : String
        "Large union types (#{THRESHOLD}+ types) — consider refactoring"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Def)
        return [] of Result unless (rt = node.return_type).is_a?(Crystal::Union)
        return [] of Result unless union_member_count(rt) >= THRESHOLD

        total = union_member_count(rt)
        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Method `#{node.name}` returns a union of #{total} types (#{THRESHOLD}+) — consider refactoring",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Reduce union size or refactor using a struct/class hierarchy",
          confidence: "medium"
        )]
      end

      private def union_member_count(type : Crystal::ASTNode) : Int32
        if type.is_a?(Crystal::Union)
          type.types.sum { |member| union_member_count(member) }
        else
          1
        end
      end

      Rule.all << self.new
    end
  end
end

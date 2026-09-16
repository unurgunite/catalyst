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
        "Large union types (#{THRESHOLD}+ non-Nil types) — consider refactoring"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Def)
        return [] of Result unless (rt = node.return_type).is_a?(Crystal::Union)
        # `Nil` members don't count: nilable unions are idiomatic Crystal,
        # not a refactoring smell. Only explicit annotations are visible —
        # unannotated defs are out of reach without type inference.
        total = non_nil_member_count(rt)
        return [] of Result unless total >= THRESHOLD

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Method `#{node.name}` returns a union of #{total} non-Nil types (#{THRESHOLD}+) — consider refactoring",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Reduce union size or refactor using a struct/class hierarchy",
          confidence: "medium"
        )]
      end

      private def non_nil_member_count(type : Crystal::ASTNode) : Int32
        if type.is_a?(Crystal::Union)
          type.types.sum { |member| non_nil_member_count(member) }
        elsif type.is_a?(Crystal::Path) && type.names == ["Nil"]
          0
        else
          1
        end
      end

      Rule.all << self.new
    end
  end
end

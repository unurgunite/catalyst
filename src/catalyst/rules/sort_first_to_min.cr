module Catalyst
  module Rules
    # # Detects `sort.first` / `sort.last` and suggests `min` / `max`.
    ##
    # # Using `sort` + `first`/`last` allocates a temporary sorted array
    # # then takes one element. `min`/`max` finds the extremum in O(n)
    # # without allocating a full sorted copy.
    class SortFirstToMin < Rule
      def id : String
        "CAT-001"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `min`/`max` instead of `sort`.`first`/`sort`.`last`"
      end

      def auto_fixable? : Bool
        true
      end

      # # Check if node is `sort.first` or `sort.last`.
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = sort_first_or_last_call(node)
        return [] of Result unless call

        replacement = call.name == "first" ? "min" : "max"
        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0
        line_text = context.line_text(line)
        fix = line_text.gsub("sort.#{call.name}", replacement)

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `#{replacement}` instead of `sort`.`#{call.name}`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `sort.#{call.name}` with `#{replacement}`",
          confidence: "high",
          fix_replacement: fix,
        )]
      end

      # # If node is `sort.first` or `sort.last`, return the outer call node.
      private def sort_first_or_last_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "first" || node.name == "last"
        return nil unless node.args.empty?
        return nil unless (target = node.obj).is_a?(Crystal::Call)
        return nil unless target.name == "sort"
        return nil unless target.args.empty?
        return nil unless target.block.nil?
        node
      end

      Rule.all << self.new
    end
  end
end

module Catalyst
  module Rules
    # # Detects `select`/`filter` + `first`/`first?` and suggests `find!`/`find`.
    ##
    # # `select` allocates an array with all matching elements then takes
    # # the first. `find`/`find!` short-circuits on the first match without
    # # allocating a full filtered array.
    class SelectFirstToFind < Rule
      SELECT_METHODS = {"select", "filter"}

      def id : String
        "CAT-008"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `find`/`find!` instead of `select`/`filter` + `first`/`first?`"
      end

      def auto_fixable? : Bool
        true
      end

      # # Check if node is `select{}.first` / `select{}.first?`.
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = select_first_call(node)
        return [] of Result unless call

        replacement = call.name == "first?" ? "find" : "find!"

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0
        line_text = context.line_text(line)
        fix = line_text.sub(/\.(?:select|filter)(\s*\{.*\})\s*\.(?:first|first\?)/) { ".#{replacement}#{$1}" }
        fix = nil if fix == line_text

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `#{replacement}` instead of `select`/`filter` + `#{call.name}`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `select{}/filter{}.#{call.name}` with `#{replacement}`",
          confidence: "high",
          fix_replacement: fix,
        )]
      end

      # # If node is `select{}.first` / `{}.first?`, return the outer call node.
      private def select_first_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "first" || node.name == "first?"
        return nil unless node.args.empty?

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless target.name.in?(SELECT_METHODS)
        return nil unless target.block

        node
      end

      Rule.all << self.new
    end
  end
end

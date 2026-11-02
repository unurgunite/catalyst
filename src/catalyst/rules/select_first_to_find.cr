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
        fix = find_fix(line_text, replacement)

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

      # # Rewrites the call on `line` to `find`/`find!`. Two passes because
      # # the trailing `?` belongs to the call being replaced: a single
      # # pattern that matched `first?` as `.first` left the `?` behind and
      # # produced `find { ... }?`, which does not parse. `.*?` keeps the
      # # block body from swallowing an enclosing block's closing brace.
      private def find_fix(line : String, replacement : String) : String?
        once = line.sub(/\.(?:select|filter)(\s*\{.*?\})\s*\.first\?/) { ".#{replacement}#{$1}" }
        once = line.sub(/\.(?:select|filter)(\s*\{.*?\})\s*\.first/) { ".#{replacement}#{$1}" } if once == line
        once == line ? nil : once
      end

      # # If node is `select{}.first` / `{}.first?`, return the outer call node.
      # # Requires a single-param block: `select { |x, i| ... }.first`
      # # cannot become `find` (it yields element only — the index is lost).
      private def select_first_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "first" || node.name == "first?"
        return nil unless node.args.empty?

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless target.name.in?(SELECT_METHODS)
        return nil unless block = target.block
        # 0 (`it`), 1 (`|x|`, `&.`, `|*a|`) are safe; 2+ would drop params.
        return nil unless block.args.size <= 1

        node
      end

      Rule.all << self.new
    end
  end
end

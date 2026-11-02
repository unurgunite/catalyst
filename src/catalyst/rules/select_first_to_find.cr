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

        filter_call = call.obj
        return [] of Result unless filter_call

        replacement = call.name == "first?" ? "find" : "find!"

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0
        line_text = context.line_text(line)
        fix = find_fix(line_text, filter_call, replacement)

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

      # # Rewrites `select{}.first` to `find`/`find!` on `line`.
      ##
      # # The span comes from the AST, not from a pattern over the text. A
      # # pattern cannot tell which `select` a `.first` belongs to: a greedy
      # # one swallowed the closing brace of an enclosing block
      # # (`Benchmark.measure { arr.select { .. }.first }` lost the outer
      # # `}`), and a lazy one still rewrote the wrong call on a shared line.
      private def find_fix(line : String, filter_call : Crystal::ASTNode, replacement : String) : String?
        select_call = filter_call.as?(Crystal::Call)
        block = select_call.try(&.block)
        # `location` points at the receiver (`arr` in `arr.select`).
        start_col = select_call.try(&.name_location.try(&.column_number))
        body_col = block.try(&.body).try(&.location.try(&.column_number))
        return nil unless block && start_col && body_col

        # First `}` at or after the body is the block's own closing brace.
        closing = line.index('}', body_col - 1)
        return nil unless closing

        # `.first`/`first?` follow the brace and are the calls being removed.
        # `.first(2)` keeps the argument form, which `find` does not have.
        rest = line[(closing + 1)..]
        return nil if rest.starts_with?(".first(")
        return nil unless rest.starts_with?(".first")
        suffix = rest.starts_with?(".first?") ? rest[7..]? : rest[6..]?

        # Keep the receiver, rename the call, keep the block, drop `.first`.
        name_end = start_col - 1 + (select_call.try(&.name.size) || 6)
        line[0...(start_col - 1)] + replacement + line[name_end..closing] + (suffix || "")
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

module Catalyst
  module Rules
    # # Detects `keys.each` and suggests `each_key`.
    ##
    # # `Hash#keys` allocates an intermediate array of keys then iterates.
    # # `Hash#each_key` iterates directly without allocation.
    class HashKeysEachToEachKey < Rule
      # Calls that mutate the receiver in place. If any of these targets
      # the iterated hash inside the block, the `each_key` suggestion is
      # unsafe (`.keys` snapshots, `each_key` iterates live) — finding
      # without a fix in that case.
      MUTATING_METHODS = Set{
        "[]=", "delete", "clear", "merge!", "update", "replace",
        "reject!", "select!", "map!", "compact!", "flatten!", "uniq!",
        "sort!", "sort_by!", "reverse!", "rotate!", "shift", "pop",
        "push", "<<", "delete_if", "keep_if",
        "transform_keys!", "transform_values!",
      }

      def id : String
        "CAT-006"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `each_key` instead of `keys.each`"
      end

      def auto_fixable? : Bool
        true
      end

      # # Check if node is `hash.keys.each`.
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = keys_each_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        if (blk = call.block) && (body = blk.body) && mutates_receiver?(call, body)
          [Result.new(
            rule_id: id,
            severity: severity,
            message: "Use `each_key` instead of `keys.each` (the block mutates the hash — verify iteration safety before converting: `.keys` snapshots, `each_key` iterates live)",
            file: context.file,
            line: line,
            column: col,
            suggestion: "Replace `keys.each` with `each_key` only if the block does not mutate the hash during iteration",
            confidence: "low",
          )]
        else
          line_text = context.line_text(line)
          fix = line_text.gsub(".keys.each", ".each_key")

          [Result.new(
            rule_id: id,
            severity: severity,
            message: "Use `each_key` instead of `keys.each`",
            file: context.file,
            line: line,
            column: col,
            suggestion: "Replace `keys.each` with `each_key`",
            confidence: "high",
            fix_replacement: fix,
          )]
        end
      end

      # # If node is `x.keys.each`, return the outer `each` call node.
      private def keys_each_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "each"
        return nil unless node.args.empty?

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless target.name == "keys"
        return nil unless target.args.empty?
        return nil unless target.block.nil?

        node
      end

      # True when the block body mutates the iterated hash. Bare-word
      # receivers (`h.keys.each`) parse as zero-arg calls, so identity is
      # (node class, name) — a method chain or constant receiver has no
      # stable identity and is treated as unknown (fix kept, status quo).
      private def mutates_receiver?(call : Crystal::Call, body : Crystal::ASTNode) : Bool
        keys = call.obj.as(Crystal::Call)
        base = keys.obj
        key = receiver_key(base)
        return false unless key
        finder = MutationFinder.new(key, MUTATING_METHODS)
        body.accept(finder)
        finder.found?
      end

      private def receiver_key(node : Crystal::ASTNode?) : {String, String}?
        case node
        when Crystal::Var, Crystal::InstanceVar, Crystal::ClassVar, Crystal::Global
          {node.class.name, node.name}
        when Crystal::Call
          if node.obj.nil? && node.args.empty? && node.block.nil?
            {node.class.name, node.name}
          end
        end
      end

      private class MutationFinder < Crystal::Visitor
        getter? found = false

        def initialize(@key : {String, String}, @mutating : Set(String))
        end

        def visit(node : Crystal::Call)
          if !found? && @mutating.includes?(node.name) && receiver_key(node.obj) == @key
            @found = true
          end
          !found?
        end

        def visit(node : Crystal::ASTNode)
          !found?
        end

        private def receiver_key(node : Crystal::ASTNode?) : {String, String}?
          case node
          when Crystal::Var, Crystal::InstanceVar, Crystal::ClassVar, Crystal::Global
            {node.class.name, node.name}
          when Crystal::Call
            if node.obj.nil? && node.args.empty? && node.block.nil?
              {node.class.name, node.name}
            end
          end
        end
      end

      Rule.all << self.new
    end
  end
end

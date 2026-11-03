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

      # # Variables assigned a Hash in this file. `each_key` exists on Hash
      # # only: a `NamedTupleLiteral` inside a macro (`.keys` there is a macro
      # # method) has no such thing, and real-world fixes turned working code
      # # into `undefined macro method 'NamedTupleLiteral#each_key'`.
      @hash_vars = Set(String).new

      def setup(file_path : String, source : String) : Nil
        @hash_vars.clear
        super
      end

      # # Check if node is `hash.keys.each`.
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        track_assign(node)

        call = keys_each_call(node)
        return [] of Result unless call

        keys = call.obj.as(Crystal::Call)
        return [] of Result unless hash_receiver?(keys.obj)

        [build_result(call, context)]
      end

      private def build_result(call : Crystal::Call, context : Context) : Result
        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        if mutating_block?(call)
          mutating_result(context, line, col)
        else
          plain_result(context, line, col)
        end
      end

      # # `.keys` snapshots the hash, `each_key` iterates it live, so a
      # # mutating block makes the rewrite unsafe — reported, but never fixed.
      private def mutating_block?(call : Crystal::Call) : Bool
        case blk = call.block
        when Crystal::Block
          body = blk.body
          body ? mutates_receiver?(call, body) : false
        else
          false
        end
      end

      private def mutating_result(context : Context, line : Int32, col : Int32) : Result
        Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `each_key` instead of `keys.each` (the block mutates the hash — verify iteration safety before converting: `.keys` snapshots, `each_key` iterates live)",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `keys.each` with `each_key` only if the block does not mutate the hash during iteration",
          confidence: "low",
        )
      end

      private def plain_result(context : Context, line : Int32, col : Int32) : Result
        Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `each_key` instead of `keys.each`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `keys.each` with `each_key`",
          confidence: "high",
          fix_replacement: sub_code(context.line_text(line), ".keys.each", ".each_key"),
        )
      end

      # # True when the receiver is recognisably a Hash.
      private def hash_receiver?(obj : Crystal::ASTNode?) : Bool
        case obj
        when Crystal::HashLiteral
          true
        when Crystal::Var, Crystal::InstanceVar, Crystal::ClassVar
          @hash_vars.includes?(obj.name)
        else
          hash_constructor?(obj)
        end
      end

      private def hash_constructor?(obj : Crystal::ASTNode?) : Bool
        return false unless obj.is_a?(Crystal::Call)
        case obj.name
        when "new"
          generic_named?(obj.obj, "Hash")
        when "of"
          obj.obj.is_a?(Crystal::HashLiteral)
        when "to_h", "group_by", "index_by"
          # These build a Hash from an Enumerable; `.keys` is then Hash#keys.
          true
        else
          false
        end
      end

      # # `Hash` and `Hash(K, V)` are a Path and a Generic respectively.
      private def generic_named?(obj : Crystal::ASTNode?, name : String) : Bool
        case obj
        when Crystal::Path
          obj.names == [name]
        when Crystal::Generic
          path = obj.name
          path.is_a?(Crystal::Path) && path.names == [name]
        else
          false
        end
      end

      private def track_assign(node : Crystal::ASTNode) : Nil
        return unless node.is_a?(Crystal::Assign)
        target = node.target
        return unless target.is_a?(Crystal::Var) || target.is_a?(Crystal::InstanceVar) || target.is_a?(Crystal::ClassVar)
        value = node.value
        name = target.name
        if value.is_a?(Crystal::HashLiteral) || hash_constructor?(value)
          @hash_vars << name
        elsif !value.is_a?(Crystal::Call)
          @hash_vars.delete(name)
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

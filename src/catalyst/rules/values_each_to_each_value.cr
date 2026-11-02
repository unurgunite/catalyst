module Catalyst
  module Rules
    # # Flags `hash.values.each { ... }`, which builds a temporary array of
    # # values; `hash.each_value { ... }` does not.
    # #
    # # `.values` is not unique to `Hash`: `Enum.values`, `NamedTuple#values`
    # # and any user type with a `values` getter reach the same shape, and
    # # `each_value` does not exist on those. The rule previously fired on all
    # # of them — every finding it produced on a 4700-file corpus was wrong.
    # # It now requires the receiver to be known a `Hash`: an explicit
    # # `Hash.new`/`Hash{...}`/`{} of ...` expression, a hash literal, or a
    # # variable assigned one of those in the same file.
    class ValuesEachToEachValue < Rule
      def id : String
        "CAT-021"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `each_value` instead of `values.each`"
      end

      def initialize
        @hash_vars = Set(String).new
      end

      def setup(file_path : String, source : String) : Nil
        @hash_vars.clear
        super
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        track_assign(node)
        call = values_each_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `each_value` instead of `values.each`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `values.each` with `each_value`",
          confidence: "medium"
        )]
      end

      private def values_each_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "each"
        return nil unless node.args.empty?

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless target.name == "values"
        return nil unless target.args.empty?
        return nil unless target.block.nil?
        return nil unless hash_receiver?(target.obj)

        node
      end

      # # True when the receiver is recognisably a Hash.
      private def hash_receiver?(obj : Crystal::ASTNode?) : Bool
        case obj
        when Crystal::HashLiteral
          true
        when Crystal::Var
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
        return unless target.is_a?(Crystal::Var)
        value = node.value
        if value.is_a?(Crystal::HashLiteral) || hash_constructor?(value)
          @hash_vars << target.name
        elsif !value.is_a?(Crystal::Call)
          @hash_vars.delete(target.name)
        end
      end

      Rule.all << self.new
    end
  end
end

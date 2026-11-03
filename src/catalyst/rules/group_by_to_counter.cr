module Catalyst
  module Rules
    class GroupByToCounter < Rule
      def id : String
        "CAT-009"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use counter hash instead of `group_by{}.map{}.size`"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = group_by_map_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use counter hash instead of `group_by{}.map{}.size`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `group_by{}.map{}.size` with `Hash.new(0)` and `h[key] += 1`",
          confidence: "medium",
        )]
      end

      private def group_by_map_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "map"
        return nil unless (map_block = node.block).is_a?(Crystal::Block)

        target = node.obj
        return nil unless target.is_a?(Crystal::Call)
        return nil unless target.name == "group_by"
        return nil unless target.block.is_a?(Crystal::Block)

        return nil unless uses_size_on_arg?(map_block)

        node
      end

      private def uses_size_on_arg?(block : Crystal::Block) : Bool
        arg_names = block.args.map(&.name)
        node_has_size_on_arg?(block.body, arg_names)
      end

      private def node_has_size_on_arg?(node : Crystal::ASTNode, arg_names : Array(String)) : Bool
        case node
        when Crystal::Call
          return true if calls_size_on_arg?(node, arg_names)
          return true if (obj = node.obj) && node_has_size_on_arg?(obj, arg_names)
          return true if node.args.any? { |arg| node_has_size_on_arg?(arg, arg_names) }
        when Crystal::TupleLiteral, Crystal::ArrayLiteral
          return true if any_child_has_size?(node.elements, arg_names)
        when Crystal::Expressions
          return true if any_child_has_size?(node.expressions, arg_names)
        end
        false
      end

      # # `<arg>.size` — the counted value is only computed to be measured.
      private def calls_size_on_arg?(call : Crystal::Call, arg_names : Array(String)) : Bool
        return false unless call.name == "size" && call.args.empty?

        obj = call.obj
        obj.is_a?(Crystal::Var) && arg_names.includes?(obj.name)
      end

      private def any_child_has_size?(children : Array(Crystal::ASTNode), arg_names : Array(String)) : Bool
        children.any? { |elem| node_has_size_on_arg?(elem, arg_names) }
      end

      Rule.all << self.new
    end
  end
end

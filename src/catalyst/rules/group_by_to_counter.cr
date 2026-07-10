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

      # ameba:disable Metrics/CyclomaticComplexity
      private def node_has_size_on_arg?(node : Crystal::ASTNode, arg_names : Array(String)) : Bool
        case node
        when Crystal::Call
          if node.name == "size" && node.args.empty?
            if (obj = node.obj).is_a?(Crystal::Var) && arg_names.includes?(obj.name)
              return true
            end
          end
          return true if (obj = node.obj) && node_has_size_on_arg?(obj, arg_names)
          return true if node.args.any? { |arg| node_has_size_on_arg?(arg, arg_names) }
        when Crystal::TupleLiteral
          return true if node.elements.any? { |elem| elem.is_a?(Crystal::ASTNode) && node_has_size_on_arg?(elem, arg_names) }
        when Crystal::ArrayLiteral
          return true if node.elements.any? { |elem| elem.is_a?(Crystal::ASTNode) && node_has_size_on_arg?(elem, arg_names) }
        when Crystal::Expressions
          return true if node.expressions.any? { |elem| elem.is_a?(Crystal::ASTNode) && node_has_size_on_arg?(elem, arg_names) }
        end
        false
      end

      Rule.all << self.new
    end
  end
end

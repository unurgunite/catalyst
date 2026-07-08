module Catalyst
  module Rules
    class StructVsClass < Rule
      ACCESSOR_METHODS = {"property", "getter", "setter"}

      def id : String
        "CAT-015"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use Struct instead of Class for small data objects"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::ClassDef)

        return [] of Result if node.struct?

        superclass = node.superclass
        return [] of Result if superclass && !reference_path?(superclass)

        ivar_count, has_non_accessor = analyze_body(node.body)

        return [] of Result if has_non_accessor
        return [] of Result if ivar_count == 0 || ivar_count > 4

        class_name = node_name_string(node.name)
        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use Struct instead of Class for `#{class_name}`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Change `class #{class_name}` to `struct #{class_name}`",
          confidence: "medium"
        )]
      end

      private def analyze_body(body : Crystal::ASTNode?) : {Int32, Bool}
        ivar_count = 0
        has_non_accessor = false

        return {ivar_count, false} unless body

        if body.is_a?(Crystal::Expressions)
          body.expressions.each do |exp|
            result = analyze_expression(exp)
            ivar_count += result[0]
            has_non_accessor = true if result[1]
          end
        else
          result = analyze_expression(body)
          ivar_count = result[0]
          has_non_accessor = result[1]
        end

        {ivar_count, has_non_accessor}
      end

      private def analyze_expression(node : Crystal::ASTNode) : {Int32, Bool}
        case node
        when Crystal::Call
          if node.name.in?(ACCESSOR_METHODS)
            count = node.args.count { |arg| arg.is_a?(Crystal::SymbolLiteral) }
            {count, false}
          else
            {0, true}
          end
        when Crystal::Def
          {0, node.name != "initialize"}
        else
          {0, true}
        end
      end

      private def reference_path?(node : Crystal::ASTNode) : Bool
        node.is_a?(Crystal::Path) && node.names == ["Reference"]
      end

      private def node_name_string(node : Crystal::ASTNode) : String
        node.is_a?(Crystal::Path) ? node.names.join("::") : node.to_s
      end

      Rule.all << self.new
    end
  end
end

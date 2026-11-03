module Catalyst
  module Rules
    # # Suggests Struct for small data-only classes.
    ##
    # # Deliberately a soft hint (info/medium), never to be promoted:
    # # value semantics (mutation through copies), `same?`/identity checks
    # # elsewhere, and future inheritance needs are invisible to a local
    # # check — one wrong promotion burns trust in the whole rule.
    class StructVsClass < Rule
      ACCESSOR_METHODS = {"property", "getter", "setter"}

      # # Classes with more ivars than this are not simple value objects.
      MAX_IVARS = 4

      @max_ivars = MAX_IVARS

      def configure(params : Hash(String, YAML::Any)) : Nil
        @max_ivars = int_param(params, "max_ivars", MAX_IVARS)
      end

      def id : String
        "CAT-015"
      end

      def severity : String
        "info"
      end

      # # Heuristic and noisy: opt-in only (`--rules #{rid}` or config
      # # `rules: {#{rid}: {enabled: true}}`).
      def enabled_by_default? : Bool
        false
      end

      def description : String
        "Use Struct instead of Class for small data objects"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::ClassDef)
        return [] of Result unless small_data_class?(node)

        [build_result(node, context)]
      end

      # # A plain class with a handful of ivars and no behaviour.
      private def small_data_class?(node : Crystal::ClassDef) : Bool
        return false if node.struct?
        superclass = node.superclass
        return false if superclass && !reference_path?(superclass)

        ivar_count, has_non_accessor = analyze_body(node.body)
        !has_non_accessor && ivar_count > 0 && ivar_count <= @max_ivars
      end

      private def build_result(node : Crystal::ClassDef, context : Context) : Result
        class_name = node_name_string(node.name)
        Result.new(
          rule_id: id,
          severity: severity,
          message: "Use Struct instead of Class for `#{class_name}`",
          file: context.file,
          line: node.location.try(&.line_number) || 0,
          column: node.name_location.try(&.column_number) || 0,
          suggestion: "Change `class #{class_name}` to `struct #{class_name}`",
          confidence: "medium"
        )
      end

      private def analyze_body(body : Crystal::ASTNode?) : {Int32, Bool}
        return {0, false} unless body

        exprs = body.is_a?(Crystal::Expressions) ? body.expressions : [body]
        total = 0
        non_accessor = false
        exprs.each do |exp|
          count, flag = analyze_expression(exp)
          total += count
          non_accessor = true if flag
        end

        {total, non_accessor}
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

module Catalyst
  module Rules
    class RegexNewToConstant < Rule
      def id : String
        "CAT-019"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Hoist `Regex.new` out of loop to a constant"
      end

      def auto_fixable? : Bool
        true
      end

      # # Constant nesting depth of the current type body:
      # # 0 = top level (constant legal), 1 = directly inside an open
      # # `class`/`module` (constant legal), nil = inside a method body
      # # (constant illegal: "dynamic constant assignment").
      def initialize
        @constant_scope = 0
      end

      def setup(file_path : String, source : String) : Nil
        @constant_scope = 0
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        track_scope_start(node)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "new" || node.name == "compile"
        return [] of Result unless (obj = node.obj).is_a?(Crystal::Path)
        return [] of Result unless obj.names == ["Regex"]

        line = node.location.try(&.line_number) || 0
        source_line = context.line_text(line)

        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Hoist `Regex.#{node.name}` out of loop to a constant",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Define `RE = Regex.#{node.name}(...)` outside the loop and reuse `RE`",
          confidence: "high",
          fix_replacement: regex_fix(call: node, line_text: source_line),
        )]
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        if type_def?(node)
          @constant_scope = @constant_scope.try(&.-(1))
        elsif node.is_a?(Crystal::Def)
          @constant_scope = @constant_scope.try(&.+(1)) if @constant_scope
        end
      end

      private def track_scope_start(node : Crystal::ASTNode) : Nil
        if type_def?(node)
          @constant_scope = @constant_scope.try(&.+(1))
        elsif node.is_a?(Crystal::Def)
          # Constants may not be assigned inside a method body, and we do not
          # know which type encloses the method, so no fix there.
          @constant_scope = nil if @constant_scope
        end
      end

      private def type_def?(node : Crystal::ASTNode) : Bool
        # `struct` parses as ClassDef as well.
        node.is_a?(Crystal::ClassDef) || node.is_a?(Crystal::ModuleDef)
      end

      # A fix may only rewrite one line, so a real hoist (constant declared
      # above the enclosing loop) is out of reach. The only shape we can fix
      # without guessing is a bare call statement that already sits in a
      # constant-legal scope: the call becomes `NAME = Regex.new(...)` on that
      # same line. Everything else gets the finding with no fix — a bare
      # undefined name or a `NAME =` inside a method body does not compile.
      private def regex_fix(call : Crystal::Call, line_text : String) : String?
        scope = @constant_scope
        return nil unless scope && scope > 0

        pattern = call.args.first?
        return nil unless pattern.is_a?(Crystal::StringLiteral)
        const_name = pattern.value.upcase.gsub(/[^A-Z0-9]+/, "_").strip("_")
        return nil if const_name.empty?
        const_name = "RX_#{const_name}" unless const_name[0].ascii_letter? && const_name[0].uppercase?

        # The call must be the whole statement — as an argument or receiver
        # the rewrite would change evaluation order.
        call_text = "Regex.#{call.name}(#{pattern})"
        indent = line_text[/\A\s*/]
        return nil unless line_text.strip == call_text

        "#{indent}#{const_name} = #{call_text}"
      end

      Rule.all << self.new
    end
  end
end

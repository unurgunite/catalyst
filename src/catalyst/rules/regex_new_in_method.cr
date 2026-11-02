module Catalyst
  module Rules
    # # Flags `Regex.new`/`Regex.compile` that rebuild the same pattern.
    # #
    # # Folding CAT-019 into this rule: both matched the identical node and
    # # reported at the same position, so every hit was duplicated and the
    # # auto-fix CAT-019 offered was itself unsound (see below). There is one
    # # rule for the subject now; CAT-019's number is retired.
    class RegexNewInMethod < Rule
      def id : String
        "CAT-039"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use class constant for `Regex.new` inside method"
      end

      def auto_fixable? : Bool
        true
      end

      # # 0 = top level, n = inside a type body (constant legal),
      # # nil = inside a `def` (a constant there is a dynamic assignment).
      @constant_scope : Int32?

      def initialize
        @constant_scope = 0
        @def_depth = 0
      end

      def setup(file_path : String, source : String) : Nil
        @constant_scope = 0
        @def_depth = 0
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        track_scope_start(node)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "new" || node.name == "compile"
        return [] of Result unless (obj = node.obj).is_a?(Crystal::Path)
        return [] of Result unless obj.names == ["Regex"]

        line = node.location.try(&.line_number) || 0
        source_line = context.line_text(line)
        return [] of Result if source_line =~ /^\s*[A-Z]\w*\s*=/

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use class constant for `Regex.#{node.name}` instead of creating inside method",
          file: context.file,
          line: line,
          column: node.name_location.try(&.column_number) || 0,
          suggestion: "Define `RE = Regex.#{node.name}(...)` as a constant and reuse",
          confidence: "high",
          fix_replacement: fix_replacement(source_line, node)
        )]
      end

      # # Rewrites `NAME = Regex.new(...)` in place, only for a call that is
      # # an entire statement in a scope where a constant is legal. A fix
      # # inside a `def` would not compile, and `.sub` on the line would
      # # also rewrite an unrelated match elsewhere in it.
      private def fix_replacement(source_line : String, node : Crystal::Call) : String?
        return nil if @def_depth > 0
        return nil unless @constant_scope

        arg = node.args.first?
        return nil unless arg.is_a?(Crystal::StringLiteral)
        name = const_name(arg.value)
        return nil if name.empty?

        # Only a line that holds nothing but the call is rewritten; the
        # original text is reused verbatim so escaping stays untouched.
        stripped = source_line.strip
        return nil unless stripped.matches?(/\ARegex\.(new|compile)\(/)
        return nil unless stripped.ends_with?(")")

        indent = source_line[/^\s*/]? || ""
        "#{indent}#{name} = #{stripped}"
      end

      private def const_name(pattern : String) : String
        name = pattern.upcase.gsub(/[^A-Z0-9]+/, "_").strip("_")
        return "" if name.empty?
        name =~ /^[0-9]/ ? "RE_#{name}" : name
      end

      private def track_scope_start(node : Crystal::ASTNode) : Nil
        case node
        when Crystal::ClassDef, Crystal::ModuleDef
          @constant_scope = @constant_scope.try(&.+(1))
        when Crystal::Def
          @def_depth += 1
          @constant_scope = nil
        end
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        case node
        when Crystal::ClassDef, Crystal::ModuleDef
          return unless @def_depth == 0
          @constant_scope = @constant_scope.try { |depth| depth - 1 }
        when Crystal::Def
          @def_depth -= 1
          # Re-entering a type body makes constants legal again.
          @constant_scope = 0 if @def_depth == 0
        end
      end

      Rule.all << self.new
    end
  end
end

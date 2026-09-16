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

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "new" || node.name == "compile"
        return [] of Result unless (obj = node.obj).is_a?(Crystal::Path)
        return [] of Result unless obj.names == ["Regex"]

        line = node.location.try(&.line_number) || 0
        source_line = context.line_text(line)
        return [] of Result if source_line =~ /^\s*[A-Z]\w*\s*=/

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

      # A constant name can only be derived from a string-literal pattern
      # on a single line — anything else (dynamic patterns, multiline)
      # gets a finding without a fix.
      private def regex_fix(call : Crystal::Call, line_text : String) : String?
        pattern = call.args.first?
        return nil unless pattern.is_a?(Crystal::StringLiteral)
        const_name = pattern.value.upcase.gsub(/[^A-Z0-9]+/, "_").strip("_")
        return nil if const_name.empty?
        const_name = "RX_#{const_name}" unless const_name[0].ascii_letter? && const_name[0].uppercase?
        call_text = "Regex.#{call.name}(#{pattern})"
        return nil unless line_text.includes?(call_text)
        line_text.sub(call_text, const_name)
      end

      Rule.all << self.new
    end
  end
end

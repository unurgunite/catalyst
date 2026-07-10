module Catalyst
  module Rules
    class ParseToConstant < Rule
      PARSE_TYPES = {
        "URI"         => ["URI"],
        "Time"        => ["Time"],
        "Time::Parse" => ["Time", "Format"],
      }

      def id : String
        "CAT-041"
      end

      def severity : String
        "info"
      end

      def description : String
        "Hoist `URI.parse`/`Time.parse` out of loop to constant"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "parse" || node.name == "parse!"
        return [] of Result unless (obj = node.obj).is_a?(Crystal::Path)

        type_name = PARSE_TYPES.find { |_, names| obj.names == names }
        return [] of Result unless type_name

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Hoist `#{type_name[0]}.#{node.name}` out of loop to a constant",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Pre-parse the value into a constant outside the loop",
          confidence: "high"
        )]
      end

      Rule.all << self.new
    end
  end
end

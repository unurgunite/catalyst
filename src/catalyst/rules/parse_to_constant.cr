module Catalyst
  module Rules
    class ParseToConstant < Rule
      PARSE_TYPES = {
        "URI"         => ["URI"],
        "Time"        => ["Time"],
        "Time::Parse" => ["Time", "Format"],
      }

      # # Block methods that imply repeated execution of their body.
      LOOP_BLOCK_METHODS = {
        "each", "each_with_index", "each_with_object",
        "times", "upto", "downto", "step", "loop",
      }

      @loop_depth : Int32 = 0

      def id : String
        "CAT-041"
      end

      def severity : String
        "info"
      end

      def description : String
        "Hoist `URI.parse`/`Time.parse` out of loop to constant"
      end

      def setup(file_path : String, source : String) : Nil
        @loop_depth = 0
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        results = check_parse(node, context)
        track_enter(node)
        results
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        track_leave(node)
      end

      private def check_parse(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "parse" || node.name == "parse!"
        return [] of Result unless (obj = node.obj).is_a?(Crystal::Path)

        type_name = PARSE_TYPES.find { |_, names| obj.names == names }
        return [] of Result unless type_name

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

        # Literal arguments are always hoistable — flag with confidence.
        # Variable arguments can only be hoisted when the same value is
        # parsed on every iteration (e.g. NOT `parse_vless(url)` called
        # with a fresh URL), so outside loops they stay silent and inside
        # loops they are low-confidence hints.
        first = node.args.first?
        if first.is_a?(Crystal::StringLiteral)
          message = "Hoist `#{type_name[0]}.#{node.name}` out of loop to a constant"
          suggestion = "Pre-parse the value into a constant outside the loop"
          confidence = "high"
        elsif @loop_depth > 0
          message = "Hoist `#{type_name[0]}.#{node.name}` out of loop to a constant if the same value is parsed on every iteration"
          suggestion = "If the argument does not change between iterations, pre-parse it once outside the loop"
          confidence = "low"
        else
          return [] of Result
        end

        [Result.new(
          rule_id: id,
          severity: severity,
          message: message,
          file: context.file,
          line: line,
          column: col,
          suggestion: suggestion,
          confidence: confidence,
        )]
      end

      private def track_enter(node : Crystal::ASTNode) : Nil
        @loop_depth += 1 if loop_opener?(node)
      end

      private def track_leave(node : Crystal::ASTNode) : Nil
        @loop_depth -= 1 if loop_opener?(node)
      end

      private def loop_opener?(node : Crystal::ASTNode) : Bool
        case node
        when Crystal::While, Crystal::Until
          true
        when Crystal::Block
          call = node.call
          call.is_a?(Crystal::Call) && LOOP_BLOCK_METHODS.includes?(call.name)
        else
          false
        end
      end

      Rule.all << self.new
    end
  end
end

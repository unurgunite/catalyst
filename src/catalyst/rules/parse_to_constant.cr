module Catalyst
  module Rules
    class ParseToConstant < Rule
      include LoopTracking
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

      def setup(file_path : String, source : String) : Nil
        super
        @varying = Set(String).new
      end

      # # Variables bound by the enclosing loop's block arguments and by
      # # assignments inside it: every iteration gives them a new value, so
      # # nothing derived from them can be hoisted.
      @varying = Set(String).new

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        # The block node is visited before the calls in its body, so its
        # arguments are already known when a call inside it is checked.
        record_varying(node)
        results = check_parse(node, context)
        track_enter(node)
        results
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        track_leave(node)
      end

      # # A block argument is rebound every iteration; a local assigned
      # # inside the loop body is too. Both make anything derived from them
      # # impossible to pre-compute.
      private def record_varying(node : Crystal::ASTNode) : Nil
        case node
        when Crystal::Block
          node.args.each { |argument| @varying << argument.name }
        when Crystal::Assign
          # Only assignments made *inside* a loop give a new value per
          # iteration; one before the loop is a perfectly good constant.
          return unless @loop_depth > 0
          target = node.target
          @varying << target.name if target.is_a?(Crystal::Var)
        end
      end

      private def check_parse(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "parse" || node.name == "parse!"
        return [] of Result unless (obj = node.obj).is_a?(Crystal::Path)

        type_name = PARSE_TYPES.find { |_, names| obj.names == names }
        return [] of Result unless type_name

        # Nothing to hoist when the call already runs once.
        return [] of Result if @loop_depth == 0

        # The advice is "parse it once outside the loop", which is only
        # sound when the argument is the same on every iteration. An
        # argument read from a loop variable is not.
        return [] of Result unless hoistable?(node)

        [build_result(node, context, type_name[0])]
      end

      private def build_result(node : Crystal::Call, context : Context, type_name : String) : Result
        call = "#{type_name}.#{node.name}"
        message, suggestion, confidence = advice(call)

        Result.new(
          rule_id: id,
          severity: severity,
          message: message,
          file: context.file,
          line: node.location.try(&.line_number) || 0,
          column: node.name_location.try(&.column_number) || 0,
          suggestion: suggestion,
          confidence: confidence,
        )
      end

      private def advice(call : String) : {String, String, String}
        {"Hoist `#{call}` out of loop to a constant",
         "Pre-parse the value into a constant outside the loop",
         "high"}
      end

      # # True when nothing in the argument list is rebound by the loop.
      # # A literal always is; a constant or a value computed outside the
      # # loop is too. Anything derived from a loop variable or a local
      # # assigned in the body is not, and hoisting it would parse the wrong
      # # value.
      private def hoistable?(node : Crystal::Call) : Bool
        argument = node.args.first?
        return true if argument.is_a?(Crystal::StringLiteral)
        return false unless argument
        names = referenced_names(argument)
        return false if names.any?(&.starts_with?('$'))
        names.none? { |name| @varying.includes?(name) }
      end

      # # Every `Var` and `InstanceVar`-free identifier the expression reads.
      private def referenced_names(node : Crystal::ASTNode) : Array(String)
        collector = NameCollector.new
        node.accept(collector)
        collector.names
      end

      # # Gathers the identifiers an argument expression reads, so the rule
      # # can ask whether the loop rebinds any of them.
      private class NameCollector < Crystal::Visitor
        getter names = [] of String

        def visit(node : Crystal::Var) : Bool
          @names << node.name
          false
        end

        # # `$0`, `$1`, `$~` are regex captures: they change on every match,
        # # so anything read from them changes per iteration too.
        def visit(node : Crystal::Global) : Bool
          @names << node.name
          false
        end

        def visit(node : Crystal::Call) : Bool
          @names << node.name if node.obj.nil?
          true
        end

        def visit(node : Crystal::ASTNode) : Bool
          true
        end
      end

      Rule.all << self.new
    end
  end
end

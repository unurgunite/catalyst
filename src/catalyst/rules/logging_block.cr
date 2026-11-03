module Catalyst
  module Rules
    # # `logger.info("user #{id}")` builds its message even when the level is
    # # disabled; `logger.info { "user #{id}" }` does not.
    ##
    # # The rule used to fire on any call named `info`/`warn`/... with an
    # # interpolated argument, whatever the receiver was. On real code that
    # # meant a project's own `Log` module, whose methods take no block: the
    # # suggested block form does not even compile
    # # ("'Log.info' is not expected to be invoked with a block"). It is now
    # # limited to receivers that have a block overload, either declared in
    # # this file or in the standard library's `::Log`.
    class LoggingBlock < Rule
      LOG_LEVELS = {"debug", "info", "warn", "error", "fatal"}
      # # Reaching the stdlib logger: `Log.info`, `::Log.info`, `Log.for(x).info`.
      LOG_PATH = "Log"

      def id : String
        "CAT-037"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use block form for logging with interpolation"
      end

      # # Method names declared with a block argument in this file.
      @block_methods = {} of String => Bool

      def setup(file_path : String, source : String) : Nil
        super
        @block_methods = MethodIndex.methods_taking_block(source)
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless LOG_LEVELS.includes?(node.name)
        return [] of Result unless node.args.first?.is_a?(Crystal::StringInterpolation)
        return [] of Result unless node.block.nil?
        return [] of Result unless block_overload?(node)

        [build_result(node, context)]
      end

      # # True when the receiver is the stdlib logger or a type in this file
      # # that declares the same method with a block. A call with no receiver
      # # (`info("...")`) is checked against this file's methods only, so a
      # # top-level script that defines neither stays silent.
      private def block_overload?(node : Crystal::Call) : Bool
        receiver = node.obj
        return @block_methods[node.name]? == true if receiver.nil?
        return true if log_path?(receiver)
        # A user-defined type: we only trust it when this file shows the
        # method really takes a block.
        @block_methods[node.name]? == true
      end

      private def log_path?(receiver : Crystal::ASTNode) : Bool
        case receiver
        when Crystal::Path
          stdlib_log?(receiver.names)
        else
          # `Log.for("x")` — look through the factory call.
          call = receiver.as?(Crystal::Call)
          return false unless call
          obj = call.obj
          return false unless obj.is_a?(Crystal::Path)
          stdlib_log?(obj.names)
        end
      end

      # # `Log` or `::Log` — the stdlib logger. `App::Log` is a project's own
      # # module and is judged by this file's method index instead, because
      # # its `info` most likely takes no block.
      private def stdlib_log?(names : Array(String)) : Bool
        names.size == 1 && names.first == LOG_PATH
      end

      private def build_result(node : Crystal::Call, context : Context) : Result
        receiver = node.obj ? "#{node.obj}." : ""
        Result.new(
          rule_id: id,
          severity: severity,
          message: "Use block form for logging: `#{receiver}#{node.name} { ... }` instead of `#{receiver}#{node.name}(\"...\#{...}\")`",
          file: context.file,
          line: node.location.try(&.line_number) || 0,
          column: node.name_location.try(&.column_number) || 0,
          suggestion: "Use block form to avoid string interpolation overhead when log level is disabled",
          confidence: "high",
        )
      end

      Rule.all << self.new
    end
  end
end

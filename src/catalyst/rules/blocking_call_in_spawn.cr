module Catalyst
  module Rules
    # # Flags blocking primitives (`Process`, `HTTP::Client`, bare `sleep`)
    # # inside a `spawn` block.
    ##
    # # Blocking the event-loop thread inside a fiber prevents every other
    # # fiber from running, so the call needs a bound.
    # #
    # # Earlier versions also carried a hardcoded list of 16 "worker wrapper"
    # # method names taken from a single codebase and scanned the bodies of
    # # those `def`s. That list was removed: on real projects it produced
    # # findings that were wrong every time (the wrappers were app-specific
    # # names) and it could not follow a call into a method with any other
    # # name. Only the generic primitive scan remains.
    class BlockingCallInSpawn < Rule
      PROCESS_METHODS = {"new", "run"}
      # # Bare `system(...)` is `Process.run` with output to stdout.
      BARE_PROCESS_METHODS = {"system"}
      HTTP_METHODS         = {"get", "post", "put", "delete", "patch", "head", "exec", "request"}

      def id : String
        "CAT-052"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Avoid blocking calls (`Process`, sockets, bare `sleep`) inside `spawn` workers — ensure a timeout/limit"
      end

      def initialize
        @spawn_depth = 0
      end

      def setup(file_path : String, source : String) : Nil
        @spawn_depth = 0
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        results = check_primitive(node, context)
        track_enter(node)
        results
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        track_leave(node)
      end

      # # Blocking primitives lexically inside `spawn`.
      private def check_primitive(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result if @spawn_depth == 0
        kind = primitive_kind(node)
        return [] of Result unless kind
        # The advice is "add a timeout"; code that already passes one is
        # not worth reporting and was a false positive on every real project.
        return [] of Result if bounded?(node)
        emit(node, context, kind)
      end

      private def primitive_kind(node : Crystal::ASTNode) : String?
        return nil unless node.is_a?(Crystal::Call)
        return "bare `sleep` (blocks the event-loop thread)" if sleep_blocking?(node)
        # `TCPSocket.new` is skipped: CAT-013 already errors on every one.
        return "`system` (spawns an OS process)" if bare_process?(node)
        return "`Process.run` (spawns an OS process)" if process_blocking?(node)
        return "`HTTP::Client` request" if http_blocking?(node)
        nil
      end

      # # `sleep N` / `sleep N.seconds` with N > 0 blocks. `sleep 0` is a
      # # yield idiom (CAT-042) — skip. Non-literal args are skipped:
      # # precision over recall.
      private def sleep_blocking?(node : Crystal::Call) : Bool
        return false unless node.obj.nil?
        return false unless node.args.size == 1
        seconds_value(node.args.first).try { |v| v > 0 } || false
      end

      private def seconds_value(arg : Crystal::ASTNode) : Float64?
        case arg
        when Crystal::NumberLiteral
          arg.value.to_f?
        when Crystal::Call
          if arg.name == "seconds" && arg.args.empty? && (obj = arg.obj).is_a?(Crystal::NumberLiteral)
            obj.value.to_f?
          end
        end
      end

      private def bare_process?(node : Crystal::Call) : Bool
        node.obj.nil? && BARE_PROCESS_METHODS.includes?(node.name)
      end

      private def process_blocking?(node : Crystal::Call) : Bool
        return false unless PROCESS_METHODS.includes?(node.name)
        obj = node.obj
        return false unless obj.is_a?(Crystal::Path)
        obj.names == ["Process"]
      end

      private def http_blocking?(node : Crystal::Call) : Bool
        return false unless HTTP_METHODS.includes?(node.name)
        obj = node.obj
        return false unless obj.is_a?(Crystal::Path)
        obj.names == ["HTTP", "Client"]
      end

      # # True when the call already carries its own timeout, so the finding
      # # would ask for something the code does. Covers a named argument and
      # # a `--max-time`-style flag passed in an argument array, which is how
      # # a wrapped `curl` bounds itself.
      private def bounded?(node : Crystal::ASTNode) : Bool
        return false unless node.is_a?(Crystal::Call)
        named = node.named_args
        return true if named.try(&.any? { |arg| TIMEOUT_ARG_NAMES.includes?(arg.name) })
        values = node.args.dup
        named.try(&.each { |arg| values << arg.value })
        values.any? { |arg| carries_timeout_flag?(arg) }
      end

      # # A `--max-time`-style flag, either as a string or as an element of
      # # an args array. This is how a wrapped `curl` bounds itself, and the
      # # rule cannot see it from the call node alone.
      private def carries_timeout_flag?(node : Crystal::ASTNode) : Bool
        case node
        when Crystal::StringLiteral
          TIMEOUT_FLAGS.any? { |flag| node.value.includes?(flag) }
        when Crystal::ArrayLiteral
          node.elements.any? { |elem| elem.is_a?(Crystal::StringLiteral) && TIMEOUT_FLAGS.any? { |flag| elem.value.includes?(flag) } }
        else
          false
        end
      end

      TIMEOUT_ARG_NAMES = {"connect_timeout", "read_timeout", "write_timeout", "timeout"}
      TIMEOUT_FLAGS     = {"--max-time", "--timeout", "--connect-timeout"}

      private def emit(node : Crystal::ASTNode, context : Context, kind : String) : Array(Result)
        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0
        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Blocking #{kind} inside `spawn` — ensure a timeout/limit so workers cannot stall the event loop",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Add a timeout (`connect_timeout`, `--max-time`), bound the wait, or move the call out of the worker",
          confidence: "medium",
        )]
      end

      private def track_enter(node : Crystal::ASTNode) : Nil
        @spawn_depth += 1 if spawn_block?(node)
      end

      private def track_leave(node : Crystal::ASTNode) : Nil
        @spawn_depth -= 1 if spawn_block?(node)
      end

      private def spawn_block?(node : Crystal::ASTNode) : Bool
        node.is_a?(Crystal::Block) && (call = node.call).is_a?(Crystal::Call) && call.name == "spawn"
      end

      Rule.all << self.new
    end
  end
end

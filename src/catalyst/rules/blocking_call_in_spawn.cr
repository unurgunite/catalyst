module Catalyst
  module Rules
    # # Blocking calls inside `spawn` workers.
    ##
    # # A worker fiber that blocks on `Process.new` (subprocess), a raw socket,
    # # or a bare `sleep` holds an event-loop thread while doing nothing.
    # # At fan-out (dozens of fibers × semaphore permits) this starves
    # # `Fiber::ExecutionContext::ThreadPool` — the shape that segfaulted
    # # in production.
    # #
    # # Three detection levels, all `warning`/`medium` (never `error`: a
    # # timeout/limit around the call is invisible statically):
    # # 1. Blocking primitives lexically inside a `spawn` block.
    # # 2. Worker-wrapper calls (`check_config`, `tcp_alive?`, ...) lexically
    # #    inside `spawn` — the blocking body lives behind a `def` boundary
    # #    (e.g. `check_config` spawns a subprocess + `sleep 1.8`).
    # # 3. Blocking primitives inside a `def` that is statically called
    # #    from `spawn` (depth ≤ 3, through `->(){}.call` lambdas): the body
    # #    scan runs when the wrapper call is seen, so forward references
    # #    (`spawn` before the `def`) still resolve.
    # # `TCPSocket.new` is skipped (CAT-013 already errors on every one —
    # # re-flagging would only duplicate). `sleep 0` is skipped (covered
    # # by CAT-042 as a yield idiom).
    class BlockingCallInSpawn < Rule
      PROCESS_METHODS = {"new", "run"}
      HTTP_METHODS    = {"get", "post", "put", "delete", "patch", "head", "exec", "request"}

      # # Worker wrappers: blocking bodies behind a `def` boundary, called
      # # from `spawn` (probe chain: check → fetch → subprocess).
      WORKER_WRAPPERS = {
        "check_config", "check_config_full", "check_remote", "check_remote_full",
        "verify_model_for_url", "verify_model",
        "fetch_ip", "fetch_country", "tcp_alive?", "port_alive?",
        "curl_via_proxy", "probe_endpoint", "app_probe_ok?",
        "trial_url", "fetch_first_working", "handle_failover",
      }

      # # `def`s that may be invoked as `name.call(...)` (lambdas stored in
      # # variables, e.g. `handle_failover = ->(t : String) do ... end`).
      CALLABLE_SUFFIX = ".call"

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
        @def_bodies = {} of String => Crystal::ASTNode
        @scanned = Set(String).new
        @pending_wrappers = [] of String
      end

      def setup(file_path : String, source : String) : Nil
        @spawn_depth = 0
        @def_bodies.clear
        @scanned.clear
        @pending_wrappers.clear
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        record_def(node)
        # Level 3 deferred pass: when the traversal reaches the root
        # `Expressions` node, every `def` in the file has been recorded
        # (preorder visits children in order, and the root is entered
        # first but its `check` runs before any child — so instead run
        # the deferred scan when leaving... `end_visit` cannot emit.
        # Solution: emit level-3 findings from `check` of the LAST
        # top-level statement is fragile. Pragmatic approach used here:
        # level-3 scans run at each wrapper-call site over defs recorded
        # SO FAR, plus a re-scan trigger: every `Def` node, after being
        # recorded, re-resolves pending wrapper calls seen earlier.
        results = check_primitive(node, context)
        results.concat(check_wrapper(node, context))
        results.concat(resolve_pending(node, context))
        track_enter(node)
        results
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        track_leave(node)
      end

      # # Remember `def` bodies and lambda bodies (`X = ->...do...end`)
      # # for level-3 reachability scans.
      private def record_def(node : Crystal::ASTNode) : Nil
        case node
        when Crystal::Def
          if body = node.body
            @def_bodies[node.name] = body
          end
        when Crystal::Assign
          if node.value.is_a?(Crystal::ProcLiteral)
            if (target = node.target).is_a?(Crystal::Var)
              if body = node.value.as(Crystal::ProcLiteral).def.body
                @def_bodies[target.name] = body
              end
            end
          end
        end
      end

      # # Level 1: blocking primitives lexically inside `spawn`.
      private def check_primitive(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result if @spawn_depth == 0
        kind = primitive_kind(node)
        return [] of Result unless kind
        emit(node, context, kind, "lexically inside `spawn`")
      end

      # # Levels 2+3: worker-wrapper calls lexically inside `spawn`.
      # # Level 2 fires on the call itself; level 3 scans the callee body
      # # (depth ≤ 3) for blocking primitives and reports them at their
      # # own lines. `@scanned` keeps one finding per def. If the callee
      # # is not recorded yet (forward reference), the name is parked in
      # # `@pending_wrappers` and resolved when its `def` appears.
      private def check_wrapper(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result if @spawn_depth == 0
        return [] of Result unless node.is_a?(Crystal::Call)
        name = callee_name(node)
        return [] of Result unless name
        return [] of Result unless WORKER_WRAPPERS.includes?(name)
        results = emit(node, context, "worker `#{name}` (blocking body: subprocess/socket/sleep)", "called from `spawn`")
        if @def_bodies.has_key?(name)
          results.concat(scan_callee(name, context, 3))
        else
          @pending_wrappers << name unless @pending_wrappers.includes?(name)
        end
        results
      end

      # # Resolve forward references: when a `def` lands, scan it if some
      # # earlier wrapper call inside `spawn` named it.
      private def resolve_pending(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Def)
        return [] of Result unless @pending_wrappers.includes?(node.name)
        scan_callee(node.name, context, 3)
      end

      # # `foo` or `foo.call` (lambda) → worker name or nil.
      # # Note: `handle_failover.call("sig")` parses with `obj` as a bare
      # # `Var`, not a zero-arg `Call` — handle both shapes.
      private def callee_name(node : Crystal::Call) : String?
        if node.name == "call" && (obj = node.obj)
          case obj
          when Crystal::Var
            obj.name
          when Crystal::Call
            if obj.args.empty? && obj.block.nil? && obj.obj.nil?
              obj.name
            end
          end
        elsif node.obj.nil?
          node.name
        end
      end

      # # Scan a callee body (and transitively its worker-wrapper callees)
      # # for blocking primitives.
      private def scan_callee(name : String, context : Context, depth : Int32) : Array(Result)
        return [] of Result if depth <= 0
        return [] of Result if @scanned.includes?(name)
        body = @def_bodies[name]?
        return [] of Result unless body
        @scanned << name
        finder = BlockingFinder.new(name, depth)
        body.accept(finder)
        finder.results(context, self)
      end

      # # Classify a node as a blocking primitive, or return nil.
      # # `TCPSocket.new`/`Socket.new` are deliberately excluded (CAT-013).
      def primitive_kind(node : Crystal::ASTNode) : String?
        return nil unless node.is_a?(Crystal::Call)
        case node.name
        when "sleep"
          sleep_blocking?(node) ? "bare `sleep` (blocks the event-loop thread)" : nil
        when "new", "run"
          process_blocking?(node) ? "`Process.#{node.name}` (spawns an OS process)" : nil
        when "get", "post", "put", "delete", "patch", "head", "exec", "request"
          http_blocking?(node) ? "`HTTP::Client##{node.name}` (blocking network I/O)" : nil
        when "system", "`"
          node.obj.nil? ? "`#{node.name}` (spawns an OS process)" : nil
        end
      end

      # # `sleep N` / `sleep N.seconds` with N > 0 blocks. `sleep 0`
      # # (and `sleep 0.seconds`) is a yield idiom (CAT-042) — skip.
      # # Non-literal args are unknown — skip (precision over recall).
      private def sleep_blocking?(node : Crystal::Call) : Bool
        return false unless node.obj.nil?
        return false unless node.args.size == 1
        seconds_value(node.args.first).try { |v| v > 0 } || false
      end

      # # Numeric seconds from `sleep 1.8` or `sleep 0.25.seconds`.
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

      def emit_at(node : Crystal::ASTNode, context : Context, kind : String, where : String) : Array(Result)
        emit(node, context, kind, where)
      end

      private def emit(node : Crystal::ASTNode, context : Context, kind : String, where : String) : Array(Result)
        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0
        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Blocking #{kind} #{where} — ensure a timeout/limit so workers cannot stall the event loop",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Add a timeout (`connect_timeout`, `--max-time`), bound the wait, or move the call out of the worker",
          confidence: "medium",
        )]
      end

      private def track_enter(node : Crystal::ASTNode) : Nil
        if node.is_a?(Crystal::Block) && (call = node.call).is_a?(Crystal::Call) && call.name == "spawn"
          @spawn_depth += 1
        end
      end

      private def track_leave(node : Crystal::ASTNode) : Nil
        if node.is_a?(Crystal::Block) && (call = node.call).is_a?(Crystal::Call) && call.name == "spawn"
          @spawn_depth -= 1
        end
      end

      # # Nested visitor: finds blocking primitives and nested worker
      # # calls inside a callee body. `!found` short-circuit is per-node,
      # # not global — every blocking site must report.
      private class BlockingFinder < Crystal::Visitor
        getter sites : Array(Crystal::Call) = [] of Crystal::Call
        getter nested : Array(String) = [] of String

        def initialize(@root : String, @depth : Int32)
        end

        def visit(node : Crystal::Call)
          if @depth > 0
            if BlockingCallInSpawn.new_for_scan.primitive_kind(node)
              @sites << node
            else
              record_nested(node)
            end
          end
          true
        end

        private def record_nested(node : Crystal::Call) : Nil
          if node.obj.nil?
            push_nested(node.name)
          elsif node.name == "call" && (obj = node.obj).is_a?(Crystal::Call) && obj.obj.nil?
            push_nested(obj.name)
          end
        end

        private def push_nested(name : String) : Nil
          return unless WORKER_WRAPPERS.includes?(name)
          return if name == @root
          @nested << name
        end

        def visit(node : Crystal::ASTNode)
          true
        end

        def results(context : Catalyst::Context, rule : BlockingCallInSpawn) : Array(Catalyst::Result)
          out = [] of Catalyst::Result
          @sites.each do |site|
            kind = rule.primitive_kind(site)
            next unless kind
            out.concat(rule.emit_at(site, context, kind, "in `#{@root}` (reached from `spawn`)"))
          end
          @nested.each do |name|
            out.concat(rule.scan_nested(name, context, @depth - 1))
          end
          out
        end
      end

      # # Transitive scan entry for the nested finder (depth already
      # # decremented by the caller).
      protected def scan_nested(name : String, context : Catalyst::Context, depth : Int32) : Array(Result)
        scan_callee(name, context, depth)
      end

      # # Lightweight instance for kind classification inside the finder
      # # (avoids threading rule state through the nested visitor).
      protected def self.new_for_scan : BlockingCallInSpawn
        BlockingCallInSpawn.new
      end

      Rule.all << self.new
    end
  end
end

module Catalyst
  module Rules
    # # Flags blocking primitives (`Process`, `HTTP::Client`, bare `sleep`)
    # # reachable from a `spawn` block.
    ##
    # # Blocking the event-loop thread inside a fiber prevents every other
    # # fiber from running, so such a call needs a bound.
    # #
    # # Detection is a reachability walk, not a name list. `setup` parses the
    # # whole file once and indexes every `def` body by method name; `check`
    # # then, for each `spawn` it sees, walks from that spawn block into the
    # # bodies of methods defined in the same file, up to `MAX_DEPTH` levels.
    # # A previous version carried a hardcoded list of 16 wrapper names from
    # # one codebase: it reported the wrong methods and missed every method
    # # not on the list. The walk has neither problem.
    # #
    # # Precision choices, each of which was a false positive on real code:
    # # - a call that already passes a timeout (`connect_timeout`,
    # #   `--max-time`, ...) is not reported;
    # # - a `sleep` bounded by an enclosing `N.times`/`N.times`, `while i < N`,
    # #   or a `select` with a `timeout` branch is not reported;
    # # - only methods defined in this file are followed, since a call into a
    # #   shard cannot be inspected and guessing is what made the old list
    # #   wrong;
    # # - `TCPSocket.new` is skipped: CAT-013 already errors on every one.
    class BlockingCallInSpawn < Rule
      PROCESS_METHODS = {"new", "run"}
      # # Bare `system(...)` is `Process.run` with output to stdout.
      BARE_PROCESS_METHODS = {"system"}
      HTTP_METHODS         = {"get", "post", "put", "delete", "patch", "head", "exec", "request"}

      # # How many method hops to follow from a `spawn` before giving up.
      MAX_DEPTH = 3

      # # Named arguments that bound a call's wait.
      TIMEOUT_ARG_NAMES = {"connect_timeout", "read_timeout", "write_timeout", "timeout", "max_time"}
      # # Flags a wrapped subprocess uses to bound itself.
      TIMEOUT_FLAGS = {"--max-time", "--timeout", "--connect-timeout"}

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
        # # Method name -> its `def` nodes, indexed once per file in `setup`.
        @defs = {} of String => Array(Crystal::Def)
        # # Lines of `spawn` blocks that a sibling `select ... timeout`
        # # bounds, collected in `setup`.
        @bounded_spawn_lines = Set(Int32).new
      end

      def setup(file_path : String, source : String) : Nil
        @spawn_depth = 0
        @defs.clear
        @bounded_spawn_lines.clear
        index_defs(source)
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        results = case node
                  when Crystal::Block
                    spawn_block?(node) ? check_spawn(node, context) : [] of Result
                  else
                    [] of Result
                  end
        track_enter(node)
        results
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        track_leave(node)
      end

      # # Index every `def` in the file by name. Parsing the source again in
      # # `setup` is what makes forward references work: a `spawn` may call a
      # # method defined further down the file, and the traversal has not
      # # reached that `def` yet when the `spawn` is checked.
      private def index_defs(source : String) : Nil
        root = Crystal::Parser.parse(source)
        root.accept(DefIndexer.new(@defs, @bounded_spawn_lines))
      rescue Crystal::SyntaxException
        # A file that does not parse yields no findings from this rule; the
        # runner reports the syntax error separately.
      end

      # # Walk out from a `spawn` block over method calls into local `def`s.
      # # Sites are de-duplicated by position: two `spawn` blocks calling the
      # # same helper both reach the same `sleep`, and reporting it twice
      # # says nothing extra.
      private def check_spawn(block : Crystal::Block, context : Context) : Array(Result)
        results = [] of Result
        sites = [] of Site
        collect_sites(block, sites)
        seen = Set(String).new
        # The indexer records the `spawn` *call* line; the visitor hands the
        # rule the block, whose own location can differ.
        spawn_line = block.call.try(&.location.try(&.line_number))
        return results if spawn_line && @bounded_spawn_lines.includes?(spawn_line)
        sites.each do |site|
          next if site.bounded
          location = site.node.location
          key = "#{location.try(&.line_number)}:#{location.try(&.column_number)}"
          next unless seen.add?(key)
          results << emit(site.node, context, site.describe)
        end
        results
      end

      # # A blocking call found by the walk, plus the call path that reached
      # # it and whether something enclosing bounds it.
      record Site,
        node : Crystal::ASTNode,
        describe : String,
        bounded : Bool

      # # Collect blocking sites reachable from `node`, following calls into
      # # local `def` bodies. `path` holds the method names already entered,
      # # so recursion terminates.
      private def collect_sites(node : Crystal::ASTNode, sites : Array(Site), path = [] of String, scope_bounded = false)
        if kind = primitive_kind(node)
          sites << Site.new(node, kind, bounded?(node) || scope_bounded)
          return
        end
        inner = scope_bounded || bounded_scope?(node)
        follow_calls(node, sites, path, inner)
        descend(node, sites, path, inner)
      end

      # # For a bare call to a method defined in this file, walk its body.
      # # A call into a local method is entered with the *caller's*
      # # boundedness: a `sleep` inside a helper called from `3.times` is
      # # bounded by that loop.
      private def follow_calls(node : Crystal::ASTNode, sites : Array(Site), path : Array(String), scope_bounded : Bool)
        return unless node.is_a?(Crystal::Call)
        return unless node.obj.nil?
        name = node.name
        return if path.includes?(name) || path.size >= MAX_DEPTH
        bodies = @defs[name]?
        return unless bodies
        bodies.each do |body|
          collect_sites(body.body, sites, path + [name], scope_bounded) if body.body
        end
      end

      # # True when `node` opens a scope that bounds everything inside it:
      # # a fixed-iteration loop (`3.times`), a `while`/`until` with a
      # # counter comparison, or a `select` that has a `timeout` branch.
      # # Each of these is real code that already limits the wait, and
      # # reporting it asks for something present.
      private def bounded_scope?(node : Crystal::ASTNode) : Bool
        case node
        when Crystal::Block
          call = node.call
          return true if call.is_a?(Crystal::Call) && call.name == "times"
          false
        when Crystal::While, Crystal::Until
          true
        when Crystal::Select
          node.whens.any? { |branch| branch.is_a?(Crystal::When) && branch.conds.any? { |cond| cond.is_a?(Crystal::Call) && cond.name == "timeout" } }
        else
          false
        end
      end

      # # Visit the direct children of `node` once. `ChildWalker` returns
      # # `false` from `visit`, so `ASTNode#accept` does not recurse into the
      # # child's own children — `collect_sites` handles that itself. Without
      # # this each subtree would be walked twice and the recursion never
      # # terminated.
      private def descend(node : Crystal::ASTNode, sites : Array(Site), path : Array(String), scope_bounded : Bool)
        node.accept_children(ChildWalker.new(self, sites, path, scope_bounded))
      end

      # # Exposed for `ChildWalker`; walks one child.
      def walk_child(child : Crystal::ASTNode, sites : Array(Site), path : Array(String), scope_bounded : Bool) : Nil
        collect_sites(child, sites, path, scope_bounded)
      end

      private def primitive_kind(node : Crystal::ASTNode) : String?
        return nil unless node.is_a?(Crystal::Call)
        return "bare `sleep` (blocks the event-loop thread)" if sleep_blocking?(node)
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
        return false unless node.name == "sleep"
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
      # # would ask for something the code does.
      private def bounded?(node : Crystal::ASTNode) : Bool
        return false unless node.is_a?(Crystal::Call)
        named = node.named_args
        return true if named.try(&.any? { |arg| TIMEOUT_ARG_NAMES.includes?(arg.name) })
        values = node.args.dup
        named.try(&.each { |arg| values << arg.value })
        values.any? { |arg| carries_timeout_flag?(arg) }
      end

      private def carries_timeout_flag?(node : Crystal::ASTNode) : Bool
        case node
        when Crystal::StringLiteral
          TIMEOUT_FLAGS.any? { |flag| node.value.includes?(flag) }
        when Crystal::ArrayLiteral
          node.elements.any? do |elem|
            elem.is_a?(Crystal::StringLiteral) && TIMEOUT_FLAGS.any? { |flag| elem.value.includes?(flag) }
          end
        else
          false
        end
      end

      private def emit(node : Crystal::ASTNode, context : Context, kind : String) : Result
        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0
        Result.new(
          rule_id: id,
          severity: severity,
          message: "Blocking #{kind} reachable from `spawn` — ensure a timeout/limit so workers cannot stall the event loop",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Add a timeout (`connect_timeout`, `--max-time`), bound the wait, or move the call out of the worker",
          confidence: "medium",
        )
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

      # # Fills a name -> defs map for one file, and records `spawn` blocks
      # # that a sibling `select ... timeout` bounds.
      # #
      # # The select case matters because `spawn { ... }` followed by
      # # `select; when timeout(...)` is the idiomatic way to bound a worker:
      # # the timeout lives next to the spawn, not inside it, so a rule that
      # # only looks inside the block always reports a bound call.
      private class DefIndexer < Crystal::Visitor
        def initialize(@defs : Hash(String, Array(Crystal::Def)), @bounded_spawn_lines : Set(Int32))
        end

        def visit(node : Crystal::ASTNode)
          true
        end

        def visit(node : Crystal::Def)
          # A `def self.x` is not reachable by a bare call, but indexing it
          # costs nothing and makes the walk tolerant of `self` receivers.
          (@defs[node.name] ||= [] of Crystal::Def) << node
          # Keep returning `true`: method bodies must be traversed so the
          # `spawn` + `select ... timeout` pre-pass sees them.
          true
        end

        def visit(node : Crystal::Expressions)
          node.expressions.each do |expr|
            next unless expr.is_a?(Crystal::Select)
            next unless select_has_timeout?(expr)
            node.expressions.each do |sibling|
              line = sibling.location.try(&.line_number)
              @bounded_spawn_lines << line if line && spawn_call?(sibling)
            end
          end
          true
        end

        # # `spawn do ... end` is a `Call` named `spawn` carrying the block,
        # # not a bare `Block` sibling.
        private def spawn_call?(node : Crystal::ASTNode) : Bool
          node.is_a?(Crystal::Call) && node.name == "spawn" && !node.block.nil?
        end

        private def select_has_timeout?(node : Crystal::Select) : Bool
          node.whens.any? do |branch|
            branch.is_a?(Crystal::When) && branch.conds.any? { |cond| cond.is_a?(Crystal::Call) && cond.name == "timeout" }
          end
        end
      end

      # # Visits the direct children of a node, delegating back to the walk.
      # # `false` stops the default traversal so each child is handled once.
      private class ChildWalker < Crystal::Visitor
        def initialize(@rule : BlockingCallInSpawn, @sites : Array(Site), @path : Array(String), @scope_bounded : Bool)
        end

        def visit(node : Crystal::ASTNode)
          @rule.walk_child(node, @sites, @path, @scope_bounded)
          false
        end
      end

      Rule.all << self.new
    end
  end
end

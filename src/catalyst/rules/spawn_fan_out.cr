module Catalyst
  module Rules
    # # Fiber fan-out: `N.times { spawn }` × semaphore permits.
    ##
    # # A worker pool shaped as `FIBERS.times { spawn { ... } }` gated by a
    # # `Channel(Nil)` counting semaphore segfaulted in production at
    # # 50 fibers × 100 permits (`Fiber::ExecutionContext::ThreadPool`
    # # starvation under hanging TCP + subprocess load). This rule
    # # multiplies the two sides and flags products over the threshold.
    # #
    # # Three tiers (maximum statically resolvable precision):
    # # - both sides resolve to ints and the product exceeds the threshold
    # #   → `warning`/`medium` on the `spawn` line, showing F×P=N;
    # # - the `times → spawn` + `Channel(Nil)` semaphore shape matches but
    # #   some operand comes from config/CLI/args (unresolvable statically —
    # #   the actual production case: `FIBER_COUNT` from ARGV, permits from
    # #   YAML) → single `info`/`low` per file: verify F×P ≤ threshold;
    # # - anything else (producers, collectors, prefills, `each` without
    # #   spawn, bare `spawn`, resolved products ≤ threshold) → silent.
    # #
    # # Semaphore recognition is structural, not nominal: `Channel(Nil)`
    # # type + nil-token prefill (`CAP.times { sem.send(nil) }`) + `receive`
    # # / `send(nil)` pairing. Task queues (`Channel(String).new(1024)`)
    # # and one-shot rendezvous never match.
    class SpawnFanOut < Rule
      # # Fibers × permits above this are a thread-pool starvation risk.
      # # Calibrated on one incident (50×100=5000 crashed, 8×8=64 lives).
      FAN_OUT_THRESHOLD = 1000

      def id : String
        "CAT-051"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Bound fiber fan-out (`N.times { spawn }` x semaphore permits) — flag products over 1000"
      end

      def initialize
        @ints = {} of String => Int32
        @sem_caps = {} of String => Int32?
        @sem_prefilled = Set(String).new
        @times_stack = [] of {String, Int32?}
        @spawn_depth = 0
        @reported = false
      end

      def setup(file_path : String, source : String) : Nil
        @ints.clear
        @sem_caps.clear
        @sem_prefilled.clear
        @times_stack.clear
        @spawn_depth = 0
        @reported = false
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        track_assign(node)
        track_semaphore_new(node)
        track_prefill(node)
        results = check_spawn(node, context)
        results.concat(check_receive(node, context))
        track_enter(node)
        results
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        track_leave(node)
      end

      # # `X = <int>` constant folding (same-file only). Any non-literal
      # # reassignment invalidates — config/CLI values stay unknown, never 0.
      private def track_assign(node : Crystal::ASTNode) : Nil
        target, value = case node
                        when Crystal::Assign
                          {node.target, node.value}
                        when Crystal::OpAssign
                          {node.target, node.value}
                        else
                          return
                        end
        name = case target
               when Crystal::Var, Crystal::InstanceVar, Crystal::ClassVar
                 target.name
               when Crystal::Path
                 target.names.last? if target.names.size == 1
               end
        return unless name
        if (lit = value).is_a?(Crystal::NumberLiteral) && (n = lit.value.to_i?)
          @ints[name] = n
        else
          @ints.delete(name)
        end
      end

      # # `sem = Channel(Nil).new(cap)` — record capacity (maybe unknown).
      private def track_semaphore_new(node : Crystal::ASTNode) : Nil
        return unless node.is_a?(Crystal::Assign)
        target, value = node.target, node.value
        return unless target.is_a?(Crystal::Var)
        call = value
        return unless call.is_a?(Crystal::Call)
        return unless call.name == "new"
        generic = call.obj
        return unless generic.is_a?(Crystal::Generic)
        gname = generic.name
        return unless gname.is_a?(Crystal::Path) && gname.names == ["Channel"]
        return unless generic.type_vars.size == 1
        tvar = generic.type_vars.first
        return unless tvar.is_a?(Crystal::Path) && tvar.names == ["Nil"]
        cap = call.args.first?
        @sem_caps[target.name] = cap ? fold_int(cap) : nil
      end

      # # `CAP.times { sem.send(nil) }` — nil-token prefill proves the
      # # channel is a counting semaphore rather than a task queue.
      private def track_prefill(node : Crystal::ASTNode) : Nil
        return unless node.is_a?(Crystal::Call)
        if send_node = nil_token_send(node)
          if @sem_caps.has_key?(send_node)
            @sem_prefilled << send_node
          end
        end
      end

      # # `CAP.times { V.send(nil) }` → semaphore variable name, else nil.
      private def nil_token_send(times_call : Crystal::Call) : String?
        return nil unless times_call.name == "times"
        block = times_call.block
        return nil unless block
        body = block.body
        return nil unless body.is_a?(Crystal::Call)
        return nil unless body.name == "send" && body.args.size == 1
        return nil unless body.args.first.is_a?(Crystal::NilLiteral)
        recv = body.obj
        return nil unless recv.is_a?(Crystal::Call) && recv.args.empty? && recv.block.nil?
        sem = recv.obj
        sem.is_a?(Crystal::Var) ? sem.name : nil
      end

      # # `spawn` inside an `N.times` block: resolve both sides.
      private def check_spawn(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Block)
        call = node.call
        return [] of Result unless call.is_a?(Crystal::Call) && call.name == "spawn"
        return [] of Result if @times_stack.empty? || @reported
        bound_name, bound = @times_stack.last
        sem = best_semaphore
        return [] of Result unless sem
        @reported = true
        resolve_product(node, context, bound_name, sem, bound, @sem_caps[sem])
      end

      # # `sem.receive` inside the fan-out nest corroborates the link
      # # between this spawn loop and this semaphore. If the `spawn`-site
      # # emission already fired, stay silent (one finding per file).
      private def check_receive(node : Crystal::ASTNode, context : Context) : Array(Result)
        sem_name = receive_semaphore(node)
        return [] of Result unless sem_name
        return [] of Result unless fan_out_context?(sem_name)
        bound_name, bound = @times_stack.last
        @reported = true
        resolve_product(node, context, bound_name, sem_name, bound, @sem_caps[sem_name])
      end

      # # `V.receive` (bare call form) inside a prefilled semaphore's
      # # fan-out nest → variable name, else nil.
      private def receive_semaphore(node : Crystal::ASTNode) : String?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "receive" && node.args.empty?
        recv = node.obj
        return nil unless recv.is_a?(Crystal::Call) && recv.args.empty? && recv.block.nil?
        sem = recv.obj
        sem.is_a?(Crystal::Var) ? sem.name : nil
      end

      # # All corroborating conditions for a receive-site verdict.
      private def fan_out_context?(sem_name : String) : Bool
        return false unless @sem_caps.has_key?(sem_name)
        return false if @spawn_depth == 0 || @times_stack.empty? || @reported
        @sem_prefilled.includes?(sem_name)
      end

      # # Prefer the prefilled semaphore; else the first recorded one.
      private def best_semaphore : String?
        @sem_prefilled.first? || @sem_caps.keys.first?
      end

      # # Shared verdict: known product over threshold → warning; known
      # # product at/below threshold → silent (un-report); anything with
      # # an unknown side → single info/low hint.
      private def resolve_product(node : Crystal::ASTNode, context : Context, bound_name : String, sem : String, bound : Int32?, cap : Int32?) : Array(Result)
        if b = bound
          if c = cap
            product = b * c
            return [] of Result if product <= FAN_OUT_THRESHOLD
            emit_known(node, context, bound_name, sem, b, c, product)
          else
            emit_unknown(node, context, bound_name, sem, "#{b} x ?")
          end
        else
          emit_unknown(node, context, bound_name, sem, "? x #{cap ? cap.to_s : "?"}")
        end
      end

      # # Resolve an int literal or a same-file constant/local.
      private def fold_int(node : Crystal::ASTNode) : Int32?
        case node
        when Crystal::NumberLiteral
          node.value.to_i?
        when Crystal::Var
          @ints[node.name]?
        when Crystal::Path
          node.names.size == 1 ? @ints[node.names.first]? : nil
        end
      end

      private def emit_known(node : Crystal::ASTNode, context : Context, bound_name : String, sem : String, fibers : Int32, permits : Int32, product : Int32) : Array(Result)
        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0
        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Fiber fan-out #{fibers} (`#{bound_name}`) x #{permits} (`#{sem}`) = #{product} exceeds #{FAN_OUT_THRESHOLD} — thread-pool starvation risk",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Lower `threads`/`max_concurrent_xray` so fibers x permits <= #{FAN_OUT_THRESHOLD}, or batch the queue in chunks with a pause",
          confidence: "medium",
        )]
      end

      private def emit_unknown(node : Crystal::ASTNode, context : Context, bound_name : String, sem : String, shape : String) : Array(Result)
        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0
        [Result.new(
          rule_id: id,
          severity: "info",
          message: "Unbounded fiber fan-out `#{bound_name}` x `#{sem}` (#{shape}; operands from config/CLI are invisible statically) — verify fibers x permits <= #{FAN_OUT_THRESHOLD}",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Check `threads` x `max_concurrent_xray` in config/CLI (crashed at 50x100=5000); lower them or batch the queue",
          confidence: "low",
        )]
      end

      private def track_enter(node : Crystal::ASTNode) : Nil
        if node.is_a?(Crystal::Block) && (call = node.call).is_a?(Crystal::Call)
          if call.name == "times"
            recv = call.obj
            bound = case recv
                    when Crystal::NumberLiteral
                      {recv.value, recv.value.to_i?}
                    when Crystal::Var
                      {recv.name, fold_int(recv)}
                    when Crystal::Path
                      recv.names.size == 1 ? {recv.names.first, fold_int(recv)} : {"?", nil}
                    else
                      {"?", nil}
                    end
            @times_stack << bound
          elsif call.name == "spawn"
            @spawn_depth += 1
          end
        end
      end

      private def track_leave(node : Crystal::ASTNode) : Nil
        if node.is_a?(Crystal::Block) && (call = node.call).is_a?(Crystal::Call)
          if call.name == "times"
            @times_stack.pop unless @times_stack.empty?
          elsif call.name == "spawn"
            @spawn_depth -= 1
          end
        end
      end

      Rule.all << self.new
    end
  end
end

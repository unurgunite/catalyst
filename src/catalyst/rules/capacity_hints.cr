module Catalyst
  module Rules
    # # A collection created without a size and then filled inside a loop
    # # pays for every growth step. The loop reveals the size, so the fix is
    # # cheap: `Array(T).new(items.size)`.
    ##
    # # Fires only when all three hold:
    ##
    # # * the collection is created empty, with no capacity argument,
    # # * it is bound to a local, and
    # # * that local is appended to (`<<`, `push`, `[]=`) inside a loop.
    ##
    # # A bare `Array(T).new` with no loop is not reported: nothing shows how
    # # big it will get, so "pre-size it" is a guess. Reporting exactly those
    # # was the old behaviour and the reason this rule had to stay opt-in.
    class CapacityHints < Rule
      COLLECTION_TYPES = {"Array", "Hash"}
      APPEND_METHODS   = {"<<", "push", "[]="}

      def id : String
        "CAT-038"
      end

      def severity : String
        "info"
      end

      def description : String
        "Pre-size a collection that a loop fills"
      end

      # # Opt-in: the size comes from the loop shape, which is an inference
      # # about intent rather than a defect in the code.
      def enabled_by_default? : Bool
        false
      end

      # # Local names appended to from inside a loop anywhere in this file.
      @filled = Set(String).new

      def setup(file_path : String, source : String) : Nil
        super
        @filled = Set(String).new
        collector = FillCollector.new
        begin
          Crystal::Parser.parse(source).accept(collector)
        rescue Crystal::SyntaxException
          return
        end
        @filled = collector.filled
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Assign)
        target = node.target
        return [] of Result unless target.is_a?(Crystal::Var)
        return [] of Result unless @filled.includes?(target.name)

        value = node.value
        return [] of Result unless value.is_a?(Crystal::Call)
        collection = unsized(value)
        return [] of Result unless collection

        [build_result(collection, value, context)]
      end

      # # The collection type in `Array(T).new` / `Hash(K, V).new` with no
      # # size argument, else nil.
      private def unsized(value : Crystal::Call) : String?
        return nil unless value.name == "new"
        return nil unless value.args.empty?

        generic = value.obj
        return nil unless generic.is_a?(Crystal::Generic)
        path = generic.name
        return nil unless path.is_a?(Crystal::Path) && path.names.size == 1

        name = path.names.first
        COLLECTION_TYPES.includes?(name) ? name : nil
      end

      private def build_result(collection : String, call : Crystal::Call, context : Context) : Result
        Result.new(
          rule_id: id,
          severity: severity,
          message: "Pre-size `#{collection}` with a capacity hint before the loop fills it",
          file: context.file,
          line: call.location.try(&.line_number) || 0,
          column: call.name_location.try(&.column_number) || 0,
          suggestion: "Create it as `#{collection}(T).new(expected_size)` to avoid repeated reallocation",
          confidence: "medium",
        )
      end

      # # Collects locals appended to while inside a loop.
      private class FillCollector < Crystal::Visitor
        getter filled = Set(String).new

        @depth = 0

        def visit(node : Crystal::ASTNode) : Bool
          record(node) if @depth > 0
          @depth += 1 if loop_opener?(node)
          true
        end

        def end_visit(node : Crystal::ASTNode) : Nil
          @depth -= 1 if loop_opener?(node)
        end

        # # `h[i] = 1` parses as a Call named `[]=`, not as an Assign.
        private def record(node : Crystal::ASTNode) : Nil
          return unless node.is_a?(Crystal::Call)
          return unless APPEND_METHODS.includes?(node.name)
          receiver = node.obj
          @filled << receiver.name if receiver.is_a?(Crystal::Var)
        end

        private def loop_opener?(node : Crystal::ASTNode) : Bool
          case node
          when Crystal::While, Crystal::Until
            true
          when Crystal::Block
            call = node.call
            call.is_a?(Crystal::Call) && LoopTracking::LOOP_BLOCK_METHODS.includes?(call.name)
          else
            false
          end
        end
      end

      Rule.all << self.new
    end
  end
end

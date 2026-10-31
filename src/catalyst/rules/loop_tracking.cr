module Catalyst
  module Rules
    # # Mixin for rules that only care about code inside a loop.
    ##
    # # Tracks nesting depth so `include?` inside a loop nested in another loop
    # # still counts, and so a sibling block after the loop is not treated as
    # # inside it. Include, call `super` in `setup`, then wrap `check`:
    ##
    # # ```
    # # def check(node, context)
    # #   track_enter(node)
    # #   ... depth is now accurate for `node` ...
    # # end
    # #
    # # def end_visit(node)
    # #   track_leave(node)
    # # end
    # # ```
    module LoopTracking
      # # Block methods whose body runs more than once.
      LOOP_BLOCK_METHODS = {
        "each", "each_with_index", "each_with_object",
        "times", "upto", "downto", "step", "loop",
      }

      # # Current loop nesting depth; 0 means top level.
      @loop_depth : Int32 = 0

      # # True when the node about to be checked sits inside a loop.
      def in_loop? : Bool
        @loop_depth > 0
      end

      # # Reset depth and call the rule's own setup.
      def setup(file_path : String, source : String) : Nil
        @loop_depth = 0
        super
      end

      # # Count a loop opener on the way down.
      def track_enter(node : Crystal::ASTNode) : Nil
        @loop_depth += 1 if loop_opener?(node)
      end

      # # Uncount a loop opener on the way back up.
      def track_leave(node : Crystal::ASTNode) : Nil
        @loop_depth -= 1 if loop_opener?(node)
      end

      # # `while`/`until` and blocks of the whitelisted iteration methods.
      def loop_opener?(node : Crystal::ASTNode) : Bool
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
    end
  end
end

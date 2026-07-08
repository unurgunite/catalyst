module Catalyst
  # # Visitor infrastructure for AST traversal.
  module Visitors
    # # Traverses AST nodes and dispatches to all active rules.
    class FileVisitor < Crystal::Visitor
      @results = [] of Result

      # # Map rules by id and prepare results buffer.
      def initialize(
        @rules : Array(Rule),
        @context : Context,
      )
      end

      # # Called by `Crystal::Visitor` for each AST node.
      # # Dispatches to all rules. Returns `true` to continue traversal.
      def visit(node : Crystal::ASTNode)
        @rules.each do |rule|
          @results.concat(rule.check(node, @context))
        end
        true
      end

      # # Collected findings after traversal.
      def results : Array(Result)
        @results
      end
    end
  end
end

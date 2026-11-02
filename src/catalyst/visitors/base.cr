module Catalyst
  # # Visitor infrastructure for AST traversal.
  module Visitors
    # # Traverses AST nodes and dispatches to all active rules.
    class FileVisitor < Crystal::Visitor
      @results = [] of Result
      # Depth of macro bodies being walked. Nodes inside `{% %}` are
      # expanded at compile time, where no runtime rewrite can apply.
      @macro_depth = 0

      # # Map rules by id and prepare results buffer.
      def initialize(
        @rules : Array(Rule),
        @context : Context,
      )
      end

      # # Called by `Crystal::Visitor` for each AST node.
      # # Dispatches to all rules. Returns `true` to continue traversal.
      def visit(node : Crystal::ASTNode)
        if macro_node?(node)
          @macro_depth += 1
          return true
        end

        # Macro bodies are expanded at compile time, where no rewrite a rule
        # could suggest is applicable. Skipping them keeps every rule honest
        # instead of each one re-implementing its own macro check.
        return true if @macro_depth > 0

        @rules.each do |rule|
          @results.concat(rule.check(node, @context))
        end
        true
      end

      def end_visit(node : Crystal::ASTNode)
        if macro_node?(node)
          @macro_depth -= 1
          return
        end

        @rules.each do |rule|
          rule.end_visit(node)
        end
      end

      # # True while the visitor is inside a macro body.
      def in_macro? : Bool
        @macro_depth > 0
      end

      # # Macro-only AST nodes. `Macro` covers the whole definition, but its
      # # `{% %}` bodies, `{% if %}` branches and `{{ }}` interpolations are
      # # separate nodes that a `Macro` check alone would already have passed.
      private def macro_node?(node : Crystal::ASTNode) : Bool
        case node
        when Crystal::Macro, Crystal::MacroExpression,
             Crystal::MacroLiteral, Crystal::MacroIf,
             Crystal::MacroFor, Crystal::MacroVar
          true
        else
          false
        end
      end

      def results : Array(Result)
        @results
      end
    end
  end
end

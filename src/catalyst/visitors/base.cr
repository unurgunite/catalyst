module Catalyst
  module Visitors
    class FileVisitor < Crystal::Visitor
      @results = [] of Result

      def initialize(
        @rules : Array(Rule),
        @context : Context
      )
      end

      def visit(node : Crystal::ASTNode)
        @rules.each do |rule|
          @results.concat(rule.check(node, @context))
        end
        true
      end

      def results : Array(Result)
        @results
      end
    end
  end
end

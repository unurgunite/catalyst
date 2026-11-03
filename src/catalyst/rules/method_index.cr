# Indexes the methods of one file so a rule can ask "what encloses
# this line?" and "does this file define a method with a block?".
#
# Rules that only see one AST node at a time cannot answer those
# questions from the node. CAT-013/025-029 needed them to stop reporting
# handles a method closes, and CAT-037 needs them to check that a
# receiver actually has a block overload before suggesting one.
module Catalyst
  module MethodIndex
    # # A method declared in the file: its name, the line range of its
    # # body (1-based, inclusive, excluding the `def` line and the closing
    # # `end`) and whether it takes a block.
    record MethodInfo,
      name : String,
      body : Range(Int32, Int32),
      takes_block : Bool,
      owner : String = ""

    # # Every `def` in `source`, keyed by the line the method starts on.
    # # Empty when the source does not parse.
    def self.index_methods(source : String) : Hash(Int32, MethodInfo)
      ast = Crystal::Parser.parse(source)
      indexer = MethodIndexer.new
      ast.accept(indexer)
      indexer.methods
    rescue Crystal::SyntaxException
      {} of Int32 => MethodInfo
    end

    # # `def` names declared in `source`, mapped to whether any of them
    # # takes a block. A name declared both with and without a block gets
    # # `true`, because a call to it could have used the block form.
    def self.methods_taking_block(source : String) : Hash(String, Bool)
      by_name = {} of String => Bool
      index_methods(source).each_value do |info|
        by_name[info.name] = by_name[info.name]? || info.takes_block
      end
      by_name
    end

    # # Method names declared in `source` that take a block, keyed by the
    # # type that declares them (`App::Log`), so a method called on one type
    # # does not inherit a block overload declared on a different one.
    def self.blocks_by_owner(source : String) : Hash(String, Set(String))
      by_owner = {} of String => Set(String)
      index_methods(source).each_value do |info|
        next unless info.takes_block
        by_owner[info.owner] ||= Set(String).new
        by_owner[info.owner] << info.name
      end
      by_owner
    end

    # # Type names (`App::Log`, `App`) and constant names declared in
    # # `source`. A bare `Log` in code is the stdlib logger only when this
    # # set does not declare something that resolves to that name.
    def self.declared_names(source : String) : Set(String)
      finder = DeclarationFinder.new
      Crystal::Parser.parse(source).accept(finder)
      finder.names
    rescue Crystal::SyntaxException
      Set(String).new
    end

    # # The body line range of the innermost method containing `line`,
    # # or nil at top level.
    def self.enclosing_method(methods : Hash(Int32, MethodInfo), line : Int32) : Range(Int32, Int32)?
      best_line = nil
      best = nil
      methods.each do |start, info|
        next unless line >= start && line <= info.body.end
        # Innermost wins when methods nest.
        if best_line.nil? || start > best_line
          best = info.body
          best_line = start
        end
      end
      best
    end

    # # The line the innermost enclosing `def` starts on, or nil at top level.
    def self.enclosing_def_line(methods : Hash(Int32, MethodInfo), line : Int32) : Int32?
      best = nil
      methods.each do |start, info|
        next unless line >= start && line <= info.body.end
        best = start if best.nil? || start > best
      end
      best
    end

    # # Collects every method without stopping at nesting.
    private class MethodIndexer < Crystal::Visitor
      getter methods = {} of Int32 => MethodInfo

      def initialize
        @scope = [] of String
      end

      def visit(node : Crystal::ASTNode)
        true
      end

      def visit(node : Crystal::ModuleDef)
        @scope.push(node.name.to_s)
        true
      end

      def visit(node : Crystal::ClassDef)
        @scope.push(node.name.to_s)
        true
      end

      def visit(node : Crystal::Def)
        start_line = node.location.try(&.line_number)
        end_line = node.end_location.try(&.line_number)
        if start_line && end_line && end_line > start_line + 1
          # 1-based, exclusive of both the `def` line and the closing `end`.
          methods[start_line] = MethodInfo.new(
            name: node.name,
            body: (start_line + 1)..(end_line - 1),
            takes_block: node.block_arg != nil,
            owner: @scope.join("::"),
          )
        end
        true
      end

      def end_visit(node : Crystal::ModuleDef)
        @scope.pop
      end

      def end_visit(node : Crystal::ClassDef)
        @scope.pop
      end
    end

    # # Type and constant names declared in a file, fully qualified.
    private class DeclarationFinder < Crystal::Visitor
      getter names = Set(String).new

      def initialize
        @scope = [] of String
      end

      def visit(node : Crystal::ASTNode)
        true
      end

      def visit(node : Crystal::ModuleDef)
        enter(node.name.to_s)
        true
      end

      def visit(node : Crystal::ClassDef)
        enter(node.name.to_s)
        true
      end

      def visit(node : Crystal::Assign)
        @names << node.target.to_s if node.target.is_a?(Crystal::Path)
        true
      end

      def end_visit(node : Crystal::ModuleDef)
        @scope.pop
      end

      def end_visit(node : Crystal::ClassDef)
        @scope.pop
      end

      private def enter(name : String) : Nil
        @scope.push(name)
        @names << @scope.join("::")
      end
    end
  end
end

module Catalyst
  module Rules
    # # `logger.info("user #{id}")` builds its message even when the level is
    # # disabled; `logger.info { "user #{id}" }` does not.
    ##
    # # The rule used to fire on any call named `info`/`warn`/... with an
    # # interpolated argument, whatever the receiver was. On real code that
    # # meant a project's own `Log` module, whose methods take no block: the
    # # suggested block form does not even compile
    # # ("'Log.info' is not expected to be invoked with a block"). It is now
    # # limited to receivers that have a block overload, either declared in
    # # this file or in the standard library's `::Log`.
    class LoggingBlock < Rule
      LOG_LEVELS   = {"debug", "info", "warn", "error", "fatal"}
      REQUIRES_LOG = %(require "log")
      # # Reaching the stdlib logger: `Log.info`, `::Log.info`, `Log.for(x).info`.
      LOG_PATH = "Log"

      def id : String
        "CAT-037"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use block form for logging with interpolation"
      end

      # # Method names declared with a block argument in this file, keyed by
      # # the type that declares them.
      @blocks_by_owner = {} of String => Set(String)
      # # Types and constants this file declares. A bare `Log` is the stdlib
      # # logger only when nothing here resolves to that name.
      @declared = Set(String).new
      # # The type whose body the current node sits in, innermost last.
      @type_stack = [] of String
      @requires_stdlib_log = false

      def setup(file_path : String, source : String) : Nil
        super
        @blocks_by_owner = MethodIndex.blocks_by_owner(source)
        @declared = MethodIndex.declared_names(source)
        @type_stack = [] of String
        @requires_stdlib_log = source.each_line.any? { |text| text.strip == REQUIRES_LOG }
      end

      # # Rules receive `check`/`end_visit` only, so the type scope is kept
      # # here rather than in a `visit` overload (which is never called).
      def end_visit(node : Crystal::ASTNode) : Nil
        case node
        when Crystal::ModuleDef, Crystal::ClassDef
          @type_stack.pop unless @type_stack.empty?
        end
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        case node
        when Crystal::ModuleDef, Crystal::ClassDef
          @type_stack.push(node.name.to_s)
        end
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless LOG_LEVELS.includes?(node.name)
        return [] of Result unless node.args.first?.is_a?(Crystal::StringInterpolation)
        return [] of Result unless node.block.nil?
        return [] of Result unless block_overload?(node)

        [build_result(node, context)]
      end

      # # True when the receiver is the stdlib logger or a type in this file
      # # that declares the same method with a block. A call with no receiver
      # # (`info("...")`) is checked against this file's methods only, so a
      # # top-level script that defines neither stays silent.
      private def block_overload?(node : Crystal::Call) : Bool
        receiver = node.obj
        return takes_block?(node.name, nil) if receiver.nil?
        names = receiver_names(receiver)
        return false unless names
        # `::Log` is unambiguous: it escapes the enclosing scopes.
        return true if names.first? == "::Log"
        owner = resolve(names)
        # A type this file declares is judged by its own block overload, so
        # one type's block-taking `info` does not vouch for another's.
        return takes_block?(node.name, owner) if owner
        # Not declared here: the only logger we can vouch for is the stdlib
        # one, reached either bare or through `Log.for(...)`.
        stdlib_log?(names)
      end

      # # `Log` reached with no declaration in this file. That is the stdlib
      # # logger only when the file actually pulls it in; a project that
      # # defines `MyApp::Log` elsewhere looks identical here, and suggesting
      # # a block form for it does not compile. Silently leaving those alone
      # # is the only answer that cannot break a build.
      private def stdlib_log?(names : Array(String)) : Bool
        return false unless names.size == 1 && names.first == LOG_PATH
        @requires_stdlib_log
      end

      # # The path a receiver names, or nil when it is not a plain path or a
      # # factory call on one (`Log.for("x").info`). `::Log` keeps its
      # # leading `::` so it can be told apart from a bare `Log`.
      private def receiver_names(receiver : Crystal::ASTNode) : Array(String)?
        call = receiver.as?(Crystal::Call)
        return names_of(receiver) unless call
        obj = call.obj
        return nil unless obj
        names_of(obj)
      end

      private def names_of(node : Crystal::ASTNode) : Array(String)?
        path = node.as?(Crystal::Path)
        return nil unless path
        # `Path#to_s` already carries the leading `::` for a global path.
        [path.to_s]
      end

      # # A fully qualified name, looked up from the innermost enclosing type
      # # outwards: `Log.info` inside `module App` tries `App::Log` first.
      private def resolve(names : Array(String)) : String?
        name = names.first?
        return nil unless name
        return name if name.starts_with?("::")
        @type_stack.reverse_each do |scope|
          candidate = "#{scope}::#{name}"
          return candidate if declared_type?(candidate)
        end
        # Only a type declared in this file can be resolved from here; a
        # bare `Log` with no declaration is left to the stdlib check.
        declared_type?(name) ? name : nil
      end

      private def declared_type?(name : String) : Bool
        @declared.includes?(name) || @declared.includes?(name.lchop("::"))
      end

      # # True when `owner` declares `method_name` with a block. A nil
      # # owner means "this file, any type", used for receiverless calls.
      private def takes_block?(method_name : String, owner : String?) : Bool
        return false if owner == "::Log"
        @blocks_by_owner.any? do |declaring_owner, names|
          next false unless names.includes?(method_name)
          owner.nil? || declaring_owner == owner
        end
      end

      private def build_result(node : Crystal::Call, context : Context) : Result
        receiver = node.obj ? "#{node.obj}." : ""
        Result.new(
          rule_id: id,
          severity: severity,
          message: "Use block form for logging: `#{receiver}#{node.name} { ... }` instead of `#{receiver}#{node.name}(\"...\#{...}\")`",
          file: context.file,
          line: node.location.try(&.line_number) || 0,
          column: node.name_location.try(&.column_number) || 0,
          suggestion: "Use block form to avoid string interpolation overhead when log level is disabled",
          confidence: "high",
        )
      end

      Rule.all << self.new
    end
  end
end

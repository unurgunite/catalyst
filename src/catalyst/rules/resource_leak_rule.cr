module Catalyst
  module Rules
    # # Shared implementation for the "resource opened without a block" family.
    ##
    # # Every member differs only in the constructor it looks for, the message
    # # it prints and its severity; the detection logic (a call with no block,
    # # on a named type) is identical.
    abstract class ResourceLeakRule < Rule
      # # Method name that acquires the resource, e.g. `open` or `new`.
      abstract def acquire_method : String
      # # Dotted type name, e.g. `File` or `HTTP::Client`.
      abstract def resource_type : String
      # # Finding text.
      abstract def message : String
      # # How to fix it.
      abstract def suggestion : String

      # # Confidence for this shape. Override for the noisier ones.
      def confidence : String
        "high"
      end

      # # Source lines, captured in `setup` so `check` can look past the
      # # acquiring line: `sock = TCPSocket.new(...)` followed by `sock.close`
      # # is correct code, and reporting it was the single largest source of
      # # false positives when this rule was run on real projects.
      @source_lines = [] of String
      # # Line ranges of every method in the file, keyed by the line the
      # # method starts on. See `MethodIndexer`.
      @methods = {} of Int32 => Range(Int32, Int32)

      def setup(file_path : String, source : String) : Nil
        @source_lines = source.lines
        @methods = index_methods(source)
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == acquire_method
        # A block means the resource is closed for us.
        return [] of Result unless node.block.nil?
        return [] of Result unless (obj = node.obj).is_a?(Crystal::Path)
        return [] of Result unless obj.names == resource_type.split("::")

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0
        return [] of Result if released_later?(line)
        return [] of Result if returned_to_caller?(line)

        [Result.new(
          rule_id: id,
          severity: severity,
          message: message,
          file: context.file,
          line: line,
          column: col,
          suggestion: suggestion,
          confidence: confidence
        )]
      end

      # # True when the enclosing method releases the resource before it
      # # returns, i.e. a `close`, `at_exit` or `ensure` appears later in the
      # # same method body.
      ##
      # # An earlier version counted `def`/`do`/`end` in the source text to
      # # find the body. That miscounted three shapes and reported code that
      # # closes its handle: a `do` inside a `def` was treated as an opener so
      # # a `sock.close` in a spec block fell outside the body, `private def`
      # # was not recognised at all so the scan escaped into a neighbouring
      # # method, and the reported line therefore depended on method order in
      # # the file. The body is now a line range taken from the parser.
      private def released_later?(line : Int32) : Bool
        body = method_body(line)
        return false unless body
        body.join('\n').matches?(/\bclose\b|\bat_exit\b|\bensure\b/)
      end

      # # True when the method only builds and configures the handle before
      # # returning it, as in `private def connect_sock(...) : TCPSocket`. The
      # # caller owns the resource then, and closing it here would break the
      # # API.
      ##
      # # The declared return type is what makes the intent explicit: without
      # # it, `sock` left on the last line is as likely an oversight as a
      # # factory, so it keeps reporting.
      private def returned_to_caller?(line : Int32) : Bool
        # Top level has no caller to hand anything back to.
        return false unless enclosing_method(line)
        return false unless returns_handle?(line)
        body = method_body(line)
        return false unless body
        return true if body.size == 1
        name = assigned_name(line)
        # Not assigned to anything, so the acquire call is the returned value.
        return true unless name
        last = body.reverse_each.find { |text| !strip_comment(text).strip.empty? }
        return false unless last
        return false unless strip_comment(last).strip == name
        # Everything in between must be configuration of the handle. A call on
        # it means the value was used here, so the method is not a factory.
        body[1...-1].all? { |text| configures_only?(strip_comment(text).strip, name) }
      end

      # # True when the enclosing `def` declares a return type.
      private def returns_handle?(line : Int32) : Bool
        start = enclosing_def_line(line)
        return false unless start
        header = strip_comment(@source_lines[start - 1]).rstrip
        header.matches?(/\)\s*:\s*\S+/) || header.matches?(/\A\s*def\s+\S+\s+:\s*\S+/)
      end

      # # Line of the `def` whose body contains `line`, or nil at top level.
      private def enclosing_def_line(line : Int32) : Int32?
        best = nil
        @methods.each do |start, span|
          next unless line >= start && line <= span.end
          best = start if best.nil? || start > best
        end
        best
      end

      # # True for a blank line, `name.something = ...`, or a plain local
      # # assignment of something else. These neither use nor release the
      # # handle, so a builder can prepare arguments and configure timeouts.
      private def configures_only?(text : String, name : String) : Bool
        return true if text.empty?
        return true if text.starts_with?("#{name}.") && text.includes?("=") && !text.includes?("==")
        # A local assignment (including the acquire line itself) neither uses
        # nor releases the handle, so a builder can prepare arguments and
        # configure timeouts before returning it.
        match = text.match(/\A(?:@|@@)?(\w+)\s*=\s*/)
        return true unless match.nil?
        # A configured method call on the handle (`f.flock_exclusive`,
        # `client.read_timeout = x`) is setup, not a release. `close` never
        # reaches here because released_later? already inspected the body.
        text.starts_with?("#{name}.")
      end

      # # Name of the variable the acquire call is assigned to on `line`.
      private def assigned_name(line : Int32) : String?
        text = strip_comment(@source_lines[line - 1])
        match = text.match(/\s*(?:@|@@)?(\w+)\s*=\s*[A-Z]/)
        match.try(&.[1])
      end

      # # Lines of the method body containing `line`. At top level this is
      # # everything below `line`, which is where a script's resource lives.
      private def method_body(line : Int32) : Array(String)?
        return nil if line <= 0 || line > @source_lines.size
        method = enclosing_method(line)
        # Everything below the acquire at top level; `line` is 1-based.
        return @source_lines[line..] unless method
        # The range is 1-based and excludes the `def` line and closing `end`.
        @source_lines[(method.begin - 1)..(method.end - 1)]
      end

      # # Line range of the method containing `line`, or nil at top level.
      private def enclosing_method(line : Int32) : Range(Int32, Int32)?
        best = nil
        @methods.each do |start, span|
          next unless line >= start && line <= span.end
          # Innermost wins when methods nest.
          best = span if best.nil? || start > best.begin
        end
        best
      end

      # # Line range of every `def` in the file, as 1-based inclusive ranges
      # # covering the body only.
      private def index_methods(source : String) : Hash(Int32, Range(Int32, Int32))
        ast = Crystal::Parser.parse(source)
        indexer = MethodIndexer.new
        ast.accept(indexer)
        indexer.ranges
      rescue Crystal::SyntaxException
        {} of Int32 => Range(Int32, Int32)
      end

      private def strip_comment(line : String) : String
        idx = line.index('#')
        idx ? line[0...idx] : line
      end

      # # Collects the body line range of every method, ignoring nesting.
      private class MethodIndexer < Crystal::Visitor
        getter ranges = {} of Int32 => Range(Int32, Int32)

        def visit(node : Crystal::ASTNode)
          true
        end

        def visit(node : Crystal::Def)
          start_line = node.location.try(&.line_number)
          end_line = node.end_location.try(&.line_number)
          if start_line && end_line && end_line > start_line + 1
            # 1-based, exclusive of both the `def` line and the closing `end`.
            ranges[start_line] = (start_line + 1)..(end_line - 1)
          end
          true
        end
      end
    end
  end
end

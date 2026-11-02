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

      def setup(file_path : String, source : String) : Nil
        @source_lines = source.lines
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
      # # returns. The scan is textual and bounded to one method body, which
      # # covers the factory shape (`sock.close` on the next line, `at_exit`
      # # registered right after, a `close` before the final `end`) without
      # # building an AST index for the whole file.
      private def released_later?(line : Int32) : Bool
        return false if line <= 0 || line > @source_lines.size
        start = enclosing_method_start(line)
        finish = method_end(start)
        return false unless finish
        body = @source_lines[(start + 1)..finish].join('\n')
        body.matches?(/\bclose\b|\bat_exit\b|\bensure\b/)
      end

      # # True when the acquire call is the value the enclosing method hands
      # # back, as in `def connect; DB.open(url); end`. The caller owns the
      # # resource then, and closing it here would break the API — the usual
      # # factory shape (`PG.connect`, `Client#open_file`).
      private def returned_to_caller?(line : Int32) : Bool
        return false if line <= 0 || line > @source_lines.size
        start = enclosing_method_start(line)
        return false if start == 0
        finish = method_end(start)
        return false unless finish

        (line...finish).each do |i|
          text = strip_comment(@source_lines[i]).strip
          next if text.empty?
          # Anything between the acquire and the method's end that is not
          # more of the same statement means the value was consumed here.
          return false unless text == strip_comment(@source_lines[line - 1]).strip
        end
        true
      end

      # # Index (0-based) of the `def` line containing `line`, or 0 at top level.
      private def enclosing_method_start(line : Int32) : Int32
        i = line - 1
        while i >= 0
          return i if @source_lines[i].lstrip.starts_with?("def ")
          i -= 1
        end
        0
      end

      # # Index (0-based) of the line closing the method opened at `start`.
      # # Tracks nesting by counting `def`/`do`/`class`/`module`/`if` style
      # # openers against `end`. Returns nil when unbalanced.
      private def method_end(start : Int32) : Int32?
        depth = 0
        i = start
        while i < @source_lines.size
          code = strip_comment(@source_lines[i])
          depth += openers(code)
          depth -= code.scan(/\bend\b/).size
          return i if depth <= 0 && i > start
          i += 1
        end
        nil
      end

      # # Openers that need a matching `end`, ignoring one-line forms.
      private def openers(code : String) : Int32
        return 0 if code.matches?(/\bend\b/)
        count = 0
        count += 1 if code.lstrip.starts_with?("def ")
        count += code.scan(/\bdo\b(?! *\|)/).size
        count += code.scan(/\bclass\b/).size
        count += code.scan(/\bmodule\b/).size
        count += code.scan(/\b(struct|enum|lib)\b/).size
        count += code.scan(/^\s*(if|unless|case|begin|while|until|select)\b/).size
        count
      end

      private def strip_comment(line : String) : String
        idx = line.index('#')
        idx ? line[0...idx] : line
      end
    end
  end
end

module Catalyst
  module Rules
    class FileReadToStreaming < Rule
      FILE_METHODS = {"read", "read_lines"}

      # # `X.from_yaml(File.read(path))` reads a config by construction —
      # # streaming it would only complicate the code.
      CONFIG_PARSE_METHODS = {"from_yaml", "from_json"}

      # # Whole-file reads of these are idiomatic: structured configs are
      # # small by convention, and streaming them only complicates the code.
      CONFIG_EXTENSIONS = {
        ".yml", ".yaml", ".json", ".toml", ".xml",
        ".ini", ".cfg", ".env",
      }

      def id : String
        "CAT-014"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use streaming instead of reading entire file at once"
      end

      def auto_fixable? : Bool
        false
      end

      # # Block methods that imply repeated execution of their body.
      LOOP_BLOCK_METHODS = {
        "each", "each_with_index", "each_with_object",
        "times", "upto", "downto", "step", "loop",
      }

      def initialize
        @config_parse_reads = Set(UInt64).new
        @loop_depth = 0
      end

      def setup(file_path : String, source : String) : Nil
        @config_parse_reads.clear
        @loop_depth = 0
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        results = check_read(node, context)
        track_enter(node)
        results
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        track_leave(node)
      end

      private def check_read(node : Crystal::ASTNode, context : Context) : Array(Result)
        # Parent (from_yaml/from_json) is visited before the nested
        # File.read, so remember reads that feed config parsing.
        if parse_call = config_parse_call(node)
          if first_arg = parse_call.args.first?
            if inner = file_read_call(first_arg)
              @config_parse_reads << inner.object_id
            end
          end
          return [] of Result
        end

        call = file_read_call(node)
        return [] of Result unless call
        return [] of Result if @config_parse_reads.includes?(call.object_id)
        return [] of Result if config_file?(call)

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        # A static check cannot know the file size: a one-off read of a
        # small file is idiomatic, a repeated whole-file read in a loop is
        # not. Loop reads stay warning/medium; one-off reads are low
        # confidence info with an if-large caveat.
        if @loop_depth > 0
          sev = severity
          message = "Use streaming (`File.open`) instead of `File.#{call.name}` for large files"
          confidence = "medium"
        else
          sev = "info"
          message = "Use streaming (`File.open`) instead of `File.#{call.name}` for large files if the file can be large"
          confidence = "low"
        end

        [Result.new(
          rule_id: id,
          severity: sev,
          message: message,
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `File.#{call.name}` with `File.open` for streaming",
          confidence: confidence,
        )]
      end

      private def track_enter(node : Crystal::ASTNode) : Nil
        @loop_depth += 1 if loop_opener?(node)
      end

      private def track_leave(node : Crystal::ASTNode) : Nil
        @loop_depth -= 1 if loop_opener?(node)
      end

      private def loop_opener?(node : Crystal::ASTNode) : Bool
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

      private def file_read_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name.in?(FILE_METHODS)

        target = node.obj
        return nil unless target.is_a?(Crystal::Path)
        return nil unless target.names == ["File"]

        node
      end

      # # True when node is `X.from_yaml(...)` / `X.from_json(...)`.
      private def config_parse_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name.in?(CONFIG_PARSE_METHODS)
        return nil if node.args.empty?

        node
      end

      # # True when the call reads a literal path with a config extension.
      private def config_file?(call : Crystal::Call) : Bool
        path_arg = call.args.first?
        return false unless path_arg.is_a?(Crystal::StringLiteral)

        CONFIG_EXTENSIONS.any? { |ext| path_arg.value.ends_with?(ext) }
      end

      Rule.all << self.new
    end
  end
end

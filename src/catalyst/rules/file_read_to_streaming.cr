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
        true
      end

      def initialize
        @config_parse_reads = Set(UInt64).new
      end

      def setup(file_path : String, source : String) : Nil
        @config_parse_reads.clear
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
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

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use streaming (`File.open`) instead of `File.#{call.name}` for large files",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `File.#{call.name}` with `File.open` for streaming",
          confidence: "medium",
        )]
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

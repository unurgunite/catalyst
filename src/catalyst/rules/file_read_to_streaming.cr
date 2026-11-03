module Catalyst
  module Rules
    class FileReadToStreaming < Rule
      include LoopTracking
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

      # # Whether a file is read whole or streamed cannot be decided from its
      # # source: the size is not in the code, and most whole-file reads are
      # # configs and fixtures where `File.read` is the right call. On 3166
      # # third-party files every finding was of that kind — tests reading
      # # fixtures, and methods returning `String` where streaming cannot fit.
      def enabled_by_default? : Bool
        false
      end

      def auto_fixable? : Bool
        false
      end

      def initialize
        @config_parse_reads = Set(UInt64).new
        @loop_depth = 0
      end

      def setup(file_path : String, source : String) : Nil
        super
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
          remember_config_read(parse_call)
          return [] of Result
        end

        call = file_read_call(node)
        return [] of Result unless call
        return [] of Result if @config_parse_reads.includes?(call.object_id)
        return [] of Result if config_file?(call)

        [build_result(call, context)]
      end

      private def remember_config_read(parse_call : Crystal::Call) : Nil
        first_arg = parse_call.args.first?
        return unless first_arg

        inner = file_read_call(first_arg)
        @config_parse_reads << inner.object_id if inner
      end

      # # A static check cannot know the file size: a one-off read of a small
      # # file is idiomatic, a repeated whole-file read in a loop is not. Loop
      # # reads stay warning/medium; one-off reads are low-confidence info
      # # with an if-large caveat.
      private def build_result(call : Crystal::Call, context : Context) : Result
        sev, message, confidence = loop_advice(call)

        Result.new(
          rule_id: id,
          severity: sev,
          message: message,
          file: context.file,
          line: call.location.try(&.line_number) || 0,
          column: call.name_location.try(&.column_number) || 0,
          suggestion: "Replace `File.#{call.name}` with `File.open` for streaming",
          confidence: confidence,
        )
      end

      private def loop_advice(call : Crystal::Call) : {String, String, String}
        if @loop_depth > 0
          {severity,
           "Use streaming (`File.open`) instead of `File.#{call.name}` for large files",
           "medium"}
        else
          {"info",
           "Use streaming (`File.open`) instead of `File.#{call.name}` for large files if the file can be large",
           "low"}
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

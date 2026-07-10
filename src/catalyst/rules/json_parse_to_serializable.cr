module Catalyst
  module Rules
    # Detects `JSON.parse(str).as_h` / `JSON.parse(str).as_a` and standalone
    # `JSON.parse(str)` (no block). Suggests `JSON::Serializable` instead.
    #
    # Manual parse+cast is brittle and verbose. `JSON::Serializable` provides
    # type-safe deserialization at compile time.
    class JsonParseToSerializable < Rule
      @visited_parse_ids : Set(UInt64)

      def initialize
        @visited_parse_ids = Set(UInt64).new
      end

      def id : String
        "CAT-012"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `JSON::Serializable` instead of `JSON.parse` with manual access"
      end

      def setup(file_path : String, source : String) : Nil
        @visited_parse_ids.clear
      end

      # Check if node is a parse+cast chain or standalone parse call.
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        if cast = parse_as_h_or_a_call(node)
          @visited_parse_ids << cast.obj.object_id
          line = cast.location.try(&.line_number) || 0
          col = cast.name_location.try(&.column_number) || 0
          method = cast.name
          return [Result.new(
            rule_id: id,
            severity: severity,
            message: "Use `JSON::Serializable` instead of `JSON.parse` with `.#{method}`",
            file: context.file,
            line: line,
            column: col,
            suggestion: "Define a `JSON::Serializable` struct and use `.from_json`",
            confidence: "high"
          )]
        end

        if standalone_parse?(node) && !@visited_parse_ids.includes?(node.object_id)
          line = node.location.try(&.line_number) || 0
          col = node.name_location.try(&.column_number) || 0
          return [Result.new(
            rule_id: id,
            severity: severity,
            message: "Use `JSON::Serializable` instead of `JSON.parse`",
            file: context.file,
            line: line,
            column: col,
            suggestion: "Define a `JSON::Serializable` struct and use `.from_json`",
            confidence: "high"
          )]
        end

        [] of Result
      end

      # Returns the outer `.as_h`/`.as_a` call if node is `JSON.parse(...).as_h` or `.as_a`.
      private def parse_as_h_or_a_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "as_h" || node.name == "as_a"
        return nil unless node.args.empty?
        return nil unless node.block.nil?
        return nil unless (target = node.obj).is_a?(Crystal::Call)
        return nil unless target.name == "parse"
        return nil if target.args.empty?
        return nil unless target.block.nil?
        return nil unless json_path?(target.obj)
        node
      end

      # Returns true if node is a standalone `JSON.parse(...)` call (no block).
      private def standalone_parse?(node : Crystal::ASTNode) : Bool
        return false unless node.is_a?(Crystal::Call)
        return false unless node.name == "parse"
        return false if node.args.empty?
        return false unless node.block.nil?
        return false unless json_path?(node.obj)
        true
      end

      # Checks if node is a Path referring to `JSON`.
      private def json_path?(node : Crystal::ASTNode?) : Bool
        return false unless node.is_a?(Crystal::Path)
        node.names == %w[JSON]
      end

      Rule.all << self.new
    end
  end
end

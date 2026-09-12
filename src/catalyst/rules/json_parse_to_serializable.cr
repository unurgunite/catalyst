module Catalyst
  module Rules
    # Detects `JSON.parse(str).as_h` / `JSON.parse(str).as_a` chains and
    # suggests `JSON::Serializable` instead.
    #
    # Manual parse+cast is brittle and verbose. `JSON::Serializable` provides
    # type-safe deserialization at compile time.
    #
    # Standalone `JSON.parse` is intentionally ignored: without a cast the
    # schema is unknown (dynamic responses, schemaless payloads), and a
    # typed struct cannot always be attached.
    class JsonParseToSerializable < Rule
      def id : String
        "CAT-012"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `JSON::Serializable` instead of `JSON.parse` with manual access"
      end

      # Check if node is a parse+cast chain.
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        cast = parse_as_h_or_a_call(node)
        return [] of Result unless cast

        line = cast.location.try(&.line_number) || 0
        col = cast.name_location.try(&.column_number) || 0
        method = cast.name

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `JSON::Serializable` instead of `JSON.parse` with `.#{method}`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Define a `JSON::Serializable` struct and use `.from_json`",
          confidence: "high",
        )]
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

      # Checks if node is a Path referring to `JSON`.
      private def json_path?(node : Crystal::ASTNode?) : Bool
        return false unless node.is_a?(Crystal::Path)
        node.names == %w[JSON]
      end

      Rule.all << self.new
    end
  end
end

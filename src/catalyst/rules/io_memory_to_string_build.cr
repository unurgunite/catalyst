module Catalyst
  module Rules
    # Detects `IO::Memory.new` + `.to_s` / `.to_string` and suggests `String.build`.
    #
    # Writing to `IO::Memory` then converting to string allocates an intermediary.
    # `String.build` is more direct and avoids `IO::Memory` overhead.
    class IoMemoryToStringBuild < Rule
      def id : String
        "CAT-020"
      end

      def severity : String
        "info"
      end

      def description : String
        "Use `String.build` instead of `IO::Memory.new` + `.to_s`"
      end

      def auto_fixable? : Bool
        true
      end

      # Check if node is a call to `to_s` or `to_string` on an `IO::Memory.new` chain.
      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        call = io_memory_to_call(node)
        return [] of Result unless call

        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `String.build` instead of `IO::Memory` chain",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Use `String.build` instead of `IO::Memory.new` chain",
          confidence: "high"
        )]
      end

      # Walk obj chain to find `IO::Memory.new` ancestor.
      private def io_memory_to_call(node : Crystal::ASTNode) : Crystal::Call?
        return nil unless node.is_a?(Crystal::Call)
        return nil unless node.name == "to_s" || node.name == "to_string"
        return nil unless node.args.empty?
        return nil unless node.block.nil?

        # Walk down the obj chain
        current = node.obj
        while current.is_a?(Crystal::Call)
          return node if current.name == "new" && io_memory_path?(current.obj)
          current = current.obj
        end
        nil
      end

      # Check if node is a Path referring to `IO::Memory`.
      private def io_memory_path?(node : Crystal::ASTNode?) : Bool
        return false unless node.is_a?(Crystal::Path)
        node.names == %w[IO Memory]
      end

      Rule.all << self.new
    end
  end
end

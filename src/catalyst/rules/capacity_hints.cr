module Catalyst
  module Rules
    class CapacityHints < Rule
      COLLECTION_TYPES = {"Array", "Hash"}

      def id : String
        "CAT-038"
      end

      def severity : String
        "info"
      end

      def description : String
        "Pre-size collections with capacity hints when size is known (opt-in: noisy on plain empty collections)"
      end

      # NOTE: deliberately opt-in. The rule cannot know whether the size
      # is actually known at the creation site, so on by default it flags
      # every plain `Array(T).new` — noise that buries real warnings.
      # Re-enable per project once loop-with-`<<` detection exists.
      def enabled_by_default? : Bool
        false
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        collection = collection_new(node)
        return [] of Result unless collection

        [build_result(collection, node, context)]
      end

      # # The collection name in `Array(T).new` / `Hash(K, V).new`, else nil.
      private def collection_new(node : Crystal::Call) : String?
        return nil unless node.name == "new"
        return nil unless node.args.empty?

        obj = node.obj
        return nil unless obj.is_a?(Crystal::Generic)
        return nil unless (path = obj.name).is_a?(Crystal::Path)

        names = path.names
        return nil unless names.size == 1

        collection = names.first
        COLLECTION_TYPES.includes?(collection) ? collection : nil
      end

      private def build_result(collection : String, call : Crystal::Call, context : Context) : Result
        Result.new(
          rule_id: id,
          severity: severity,
          message: "Pre-size `#{collection}` with capacity hint via `.new(capacity)` when size is known",
          file: context.file,
          line: call.location.try(&.line_number) || 0,
          column: call.name_location.try(&.column_number) || 0,
          suggestion: "Use `#{collection}(Type).new(expected_size)` to avoid reallocations",
          confidence: "medium",
        )
      end

      Rule.all << self.new
    end
  end
end

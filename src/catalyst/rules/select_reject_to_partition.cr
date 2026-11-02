module Catalyst
  module Rules
    # # Detects `select{...}` + `reject{...}` on same receiver → suggests `partition`.
    ##
    # # Using `select` then `reject` on the same collection iterates twice.
    # # `partition` does both in a single pass.
    class SelectRejectToPartition < Rule
      def id : String
        "CAT-003"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Use `partition` instead of `select` followed by `reject`"
      end

      def initialize
        @select_calls = {} of String => Crystal::Call
        @reject_calls = {} of String => Crystal::Call
        @scope = [] of String
      end

      def setup(file_path : String, source : String) : Nil
        @select_calls.clear
        @reject_calls.clear
        @scope.clear
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        # Track which method a call sits in. Two calls in different methods
        # are not a select/reject pair, even when the receiver is spelled the
        # same — `results.reject` in one helper and `results.select` in
        # another read identically as `obj.to_s`.
        enter_scope(node)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "select" || node.name == "reject"
        return [] of Result unless node.block
        return [] of Result unless obj = node.obj

        key = "#{@scope.join('/')}\u0000#{obj}"

        if node.name == "select"
          if @reject_calls.has_key?(key)
            @reject_calls.delete(key)
            return partition_result(node, key, context)
          else
            @select_calls[key] = node
          end
        else
          if @select_calls.has_key?(key)
            select_call = @select_calls[key]
            @select_calls.delete(key)
            return partition_result(select_call, key, context)
          else
            @reject_calls[key] = node
          end
        end

        [] of Result
      end

      private def enter_scope(node : Crystal::ASTNode) : Nil
        @scope << node.name if node.is_a?(Crystal::Def)
      end

      def end_visit(node : Crystal::ASTNode) : Nil
        # Pop only our own push: the root `Expressions` never reaches `check`.
        @scope.pop if node.is_a?(Crystal::Def) && !@scope.empty?
      end

      private def partition_result(call : Crystal::Call, key : String, context : Context) : Array(Result)
        line = call.location.try(&.line_number) || 0
        col = call.name_location.try(&.column_number) || 0

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Use `partition` instead of `select` followed by `reject` on `#{key}`",
          file: context.file,
          line: line,
          column: col,
          suggestion: "Replace `select{...}` and `reject{...}` with `partition{...}`",
          confidence: "medium"
        )]
      end

      Rule.all << self.new
    end
  end
end

module Catalyst
  module Rules
    class MultiPassGsub < Rule
      @counted : Array(Crystal::ASTNode)

      def initialize
        @counted = [] of Crystal::ASTNode
      end

      def id : String
        "CAT-011"
      end

      def severity : String
        "info"
      end

      def description : String
        "Combine multiple `gsub` calls into a single pass"
      end

      def setup(file_path : String, source : String)
        @counted.clear
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == "gsub"

        receiver = node.obj
        return [] of Result unless receiver.is_a?(Crystal::Call)
        return [] of Result unless receiver.name == "gsub"
        return [] of Result if counted_in_chain?(node)

        chain = collect_chain(node)
        @counted.concat(chain)

        # A hash `gsub` replaces every match in one pass, so a chain whose
        # replacement is itself matched by a later step produces different
        # text: `gsub('a', "%").gsub('%', "X")` gives "XX" but the hash
        # form gives "%X". Only independent steps can be merged.
        return [] of Result if steps_interact?(chain)

        [Result.new(
          rule_id: id,
          severity: severity,
          message: "Combine multiple `gsub` calls into a single pass",
          file: context.file,
          line: node.location.try(&.line_number) || 0,
          column: node.name_location.try(&.column_number) || 0,
          suggestion: "Combine multiple `gsub` calls into a single `gsub` with a hash argument",
          confidence: "medium",
        )]
      end

      private def counted_in_chain?(node : Crystal::Call) : Bool
        current = node
        while current.is_a?(Crystal::Call) && current.name == "gsub"
          return true if @counted.any?(&.same?(current))
          current = current.obj
        end
        false
      end

      private def collect_chain(node : Crystal::Call) : Array(Crystal::Call)
        chain = [] of Crystal::Call
        current = node
        while current.is_a?(Crystal::Call) && current.name == "gsub"
          chain << current
          current = current.obj
        end
        chain
      end

      # True when one step's replacement can be matched by any step's
      # pattern, which makes the merged hash behave differently.
      private def steps_interact?(chain : Array(Crystal::Call)) : Bool
        patterns = chain.compact_map { |step| literal_step(step, 0) }
        replacements = chain.compact_map { |step| literal_step(step, 1) }
        return true if patterns.empty? || replacements.empty?

        replacements.any? do |replacement|
          # An empty replacement cannot introduce a new match.
          next false if replacement.empty?
          patterns.any? { |pattern| !pattern.empty? && replacement.includes?(pattern) }
        end
      end

      # Text of a literal argument, or nil when it is dynamic.
      private def literal_step(step : Crystal::Call, index : Int32) : String?
        arg = step.args[index]?
        case arg
        when Crystal::StringLiteral
          arg.value
        when Crystal::CharLiteral
          arg.value.to_s
        when Crystal::RegexLiteral
          value = arg.value
          value.is_a?(Crystal::StringLiteral) ? value.value : nil
        end
      end

      Rule.all << self.new
    end
  end
end

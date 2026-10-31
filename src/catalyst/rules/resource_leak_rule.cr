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

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        return [] of Result unless node.is_a?(Crystal::Call)
        return [] of Result unless node.name == acquire_method
        # A block means the resource is closed for us.
        return [] of Result unless node.block.nil?
        return [] of Result unless (obj = node.obj).is_a?(Crystal::Path)
        return [] of Result unless obj.names == resource_type.split("::")

        line = node.location.try(&.line_number) || 0
        col = node.name_location.try(&.column_number) || 0

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
    end
  end
end

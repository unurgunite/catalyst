module Catalyst
  # # Base class for output formatters.
  ##
  # # Subclasses must implement `#output` to write findings to IO.
  abstract class Formatter
    # # Factory: select formatter by name.
    # # Returns `Terminal`, `Json`, or `Sarif` instance.
    def self.for(name : String) : Formatter
      case name.downcase
      when "json"  then Formatters::Json.new
      when "sarif" then Formatters::Sarif.new
      else              Formatters::Terminal.new
      end
    end

    # # Write formatted results to IO, filtered by minimum severity.
    abstract def output(results : Array(Result), io : IO, min_severity : String) : Nil
  end
end

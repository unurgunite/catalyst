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

    # # Keep findings at or above `min_severity`.
    ##
    # # `SEVERITY_LEVELS` is ordered most severe first, so "at least this
    # # severe" is an index <= the minimum's index. An unknown level sorts
    # # to the least severe end rather than silently matching everything.
    protected def filter_by_severity(results : Array(Result), min_severity : String) : Array(Result)
      levels = CLI::SEVERITY_LEVELS
      min_idx = levels.index(min_severity) || (levels.size - 1)
      results.select { |result| severity_index(result.severity) <= min_idx }
    end

    protected def severity_index(severity : String) : Int32
      CLI::SEVERITY_LEVELS.index(severity) || (CLI::SEVERITY_LEVELS.size - 1)
    end
  end
end

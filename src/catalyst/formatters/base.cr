module Catalyst
  abstract class Formatter
    def self.for(name : String) : Formatter
      case name.downcase
      when "json"  then Formatters::Json.new
      when "sarif" then Formatters::Sarif.new
      else              Formatters::Terminal.new
      end
    end

    abstract def output(results : Array(Result), io : IO, min_severity : String) : Nil
  end
end

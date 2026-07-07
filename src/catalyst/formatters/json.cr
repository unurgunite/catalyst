require "json"

module Catalyst
  module Formatters
    class Json < Formatter
      def output(results : Array(Result), io : IO, min_severity : String) : Nil
        filtered = results.select { |r| severity_level(r.severity) >= severity_level(min_severity) }
        io.puts filtered.to_json
      end

      private def severity_level(severity : String) : Int32
        %w(error warning info hint).index(severity) || 0
      end
    end

    class Sarif < Formatter
      def output(results : Array(Result), io : IO, min_severity : String) : Nil
        filtered = results.select { |r| severity_level(r.severity) >= severity_level(min_severity) }
        sarif = generate_sarif(filtered)
        io.puts sarif.to_json
      end

      private def generate_sarif(results : Array(Result))
        {
          "$schema" => "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
          "version" => "2.1.0",
          "runs"    => [
            {
              "tool"    => {
                "driver" => {
                  "name"           => "catalyst",
                  "version"        => VERSION,
                  "informationUri" => "https://catalyst.dev",
                },
              },
              "results" => results.map { |r|
                {
                  "ruleId"       => r.rule_id,
                  "level"        => r.severity == "error" ? "error" : "warning",
                  "message"      => {"text" => r.message},
                  "locations"    => [
                    {
                      "physicalLocation" => {
                        "artifactLocation" => {"uri" => r.file},
                        "region"           => {
                          "startLine"   => r.line,
                          "startColumn" => r.column,
                        },
                      },
                    },
                  ],
                }
              },
            },
          ],
        }
      end

      private def severity_level(severity : String) : Int32
        %w(error warning info hint).index(severity) || 0
      end
    end
  end
end

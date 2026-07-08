require "json"

module Catalyst
  module Formatters
    # # JSON array output. Each result is a JSON object in the array.
    class Json < Formatter
      # # Write findings as a JSON array to IO.
      def output(results : Array(Result), io : IO, min_severity : String) : Nil
        filtered = results.select { |result| severity_level(result.severity) >= severity_level(min_severity) }
        io.puts filtered.to_json
      end

      private def severity_level(severity : String) : Int32
        %w(error warning info hint).index(severity) || 0
      end
    end

    # # SARIF 2.1.0 output format.
    # # Complies with OASIS SARIF specification for integration
    # # with GitHub Code Scanning, VS Code, and other tools.
    class Sarif < Formatter
      # # Write findings as a SARIF document to IO.
      def output(results : Array(Result), io : IO, min_severity : String) : Nil
        filtered = results.select { |result| severity_level(result.severity) >= severity_level(min_severity) }
        sarif = generate_sarif(filtered)
        io.puts sarif.to_json
      end

      private def generate_sarif(results : Array(Result))
        {
          "$schema" => "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
          "version" => "2.1.0",
          "runs"    => [
            {
              "tool" => {
                "driver" => {
                  "name"           => "catalyst",
                  "version"        => VERSION,
                  "informationUri" => "https://catalyst.dev",
                },
              },
              "results" => results.map { |result|
                {
                  "ruleId"    => result.rule_id,
                  "level"     => result.severity == "error" ? "error" : "warning",
                  "message"   => {"text" => result.message},
                  "locations" => [
                    {
                      "physicalLocation" => {
                        "artifactLocation" => {"uri" => result.file},
                        "region"           => {
                          "startLine"   => result.line,
                          "startColumn" => result.column,
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

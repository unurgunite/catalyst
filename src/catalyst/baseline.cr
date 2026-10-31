require "json"

module Catalyst
  # # Persistent baseline of known findings for regression gating.
  #
  # A baseline stores finding keys (`file:rule:message`) as a JSON array.
  # Runs with `--baseline` report only findings absent from the file, so CI
  # can gate on new issues while grandfathering existing ones.
  # Keys intentionally exclude line numbers: findings survive line shifts,
  # at the cost of not noticing a finding that moved files.
  class Baseline
    # # Build a stable key for a finding.
    def self.key(result : Result) : String
      "#{result.file}:#{result.rule_id}:#{result.message}"
    end

    # # Load known keys from a baseline file. Missing file means everything
    # # is new — the correct behavior for a gate on first run.
    # # Raises `ConfigError` on unreadable or corrupt content: silently treating
    # # a corrupt baseline as "no baseline" would report every finding as new,
    # # and silently treating it as "everything known" would hide them.
    def self.load(path : String) : Set(String)
      return Set(String).new unless File.exists?(path)

      begin
        Array(String).from_json(File.read(path)).to_set
      rescue ex : JSON::ParseException
        raise ConfigError.new("baseline #{path} is not valid JSON: #{ex.message}")
      rescue ex : File::Error | IO::Error
        raise ConfigError.new("baseline #{path} could not be read: #{ex.message}")
      end
    end

    # # Write all findings as the new baseline. Returns the entry count.
    def self.write(path : String, results : Array(Result)) : Int32
      keys = results.map { |result| key(result) }.sort!.uniq!
      begin
        File.write(path, keys.to_json)
      rescue ex : File::Error | IO::Error
        raise ConfigError.new("baseline #{path} could not be written: #{ex.message}")
      end
      keys.size
    end

    # # Keep only findings absent from the known set.
    def self.new_findings(results : Array(Result), known : Set(String)) : Array(Result)
      results.reject { |result| known.includes?(key(result)) }
    end
  end
end

require "yaml"

module Catalyst
  # # Raised when `.catalyst.yml` cannot be parsed into a `Config`.
  # # Carries a human-readable message (file + what was expected);
  # # the CLI prints it as a one-liner instead of a raw stacktrace.
  class ConfigError < Exception
  end

  # # Per-rule overrides: enabled state, severity, and free-form params.
  struct RuleConfig
    include YAML::Serializable
    # # Whether the rule is enabled.
    property? enabled : Bool = true
    # # Override severity for this rule (optional).
    property severity : String? = nil
    # # Rule-specific tuning values (optional), e.g. `threshold: 500`.
    property params : Hash(String, YAML::Any)? = nil
  end

  # # Application configuration loaded from `.catalyst.yml`.
  ##
  # # Every key has a default, so a partial file only overrides what it names.
  struct Config
    include YAML::Serializable

    # # Severity levels accepted in config and on the CLI, most severe first.
    SEVERITIES = %w[error warning info hint]
    # # Output formats accepted in config and on the CLI.
    FORMATS = %w[terminal json sarif]

    # # Minimum severity level to display.
    property severity : String = "warning"
    # # Output format: terminal, json, or sarif.
    property format : String = "terminal"
    # # Per-rule configuration overrides keyed by rule ID.
    property rules : Hash(String, RuleConfig) = {} of String => RuleConfig
    # # Glob patterns for files to ignore.
    property ignore : Array(String) = [] of String
    # # Source paths to analyze.
    property paths : Array(String) = [] of String

    # # Return default config with sensible defaults.
    def self.default : Config
      Config.from_yaml("{}")
    end

    # # Load config from YAML file path. Fallback to default if missing.
    # # Raises `ConfigError` with a human-readable message on bad input.
    def self.load(path : String = ".catalyst.yml") : Config
      return default unless File.exists?(path)
      config = parse_file(path)
      config.validate!(path)
      config
    end

    # # Read and parse one config file. Raises `ConfigError` on bad input.
    private def self.parse_file(path : String) : Config
      from_yaml(File.read(path))
    rescue ex : ConfigError
      raise ex
    rescue ex : YAML::ParseException
      raise ConfigError.new(
        "config error in #{path}: #{ex.message} — " \
        "expected mappings like `rules: {CAT-001: {enabled: false}}`"
      )
    rescue ex : File::Error | IO::Error
      # Permissions, path-is-a-directory, or the file vanishing between the
      # existence check and the read.
      raise ConfigError.new("config error in #{path}: #{ex.message}")
    end

    # # Check enum fields and rule IDs. Raises `ConfigError` on bad values.
    def validate!(path : String) : Nil
      validate_enum(path, "severity", severity, SEVERITIES)
      validate_enum(path, "format", format.downcase, FORMATS)
      rules.each { |rule_id, rule_config| validate_rule(path, rule_id, rule_config) }
    end

    # # Reject a value that is not one of the documented levels.
    private def validate_enum(path : String, field : String, value : String, allowed : Array(String)) : Nil
      return if allowed.includes?(value)

      raise ConfigError.new(
        "config error in #{path}: #{field} #{value.inspect} is not one of #{allowed.join("|")}"
      )
    end

    private def validate_rule(path : String, rule_id : String, rule_config : RuleConfig) : Nil
      # A typo here silently disabling a rule is worse than a loud failure.
      unless known_rule_id?(rule_id)
        raise ConfigError.new("config error in #{path}: unknown rule #{rule_id.inspect} in `rules`")
      end
      return unless rule_severity = rule_config.severity

      validate_enum(path, "severity for #{rule_id}", rule_severity, SEVERITIES)
    end

    # Rules are registered at require time, so the registry is authoritative.
    private def known_rule_id?(rule_id : String) : Bool
      Rule.all.any? { |rule| rule.id == rule_id }
    end
  end

  # # Delegating loader for config resolution.
  class ConfigLoader
    # # Load config from given path.
    def self.load(path : String) : Config
      Config.load(path)
    end
  end
end

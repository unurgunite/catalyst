require "yaml"

module Catalyst
  ## Per-rule overrides for severity and enabled state.
  struct RuleConfig
    include YAML::Serializable
    ## Whether the rule is enabled.
    property enabled : Bool = true
    ## Override severity for this rule (optional).
    property severity : String? = nil
  end

  ## Application configuration loaded from `.catalyst.yml`.
  struct Config
    include YAML::Serializable

    ## Minimum severity level to display.
    property severity : String
    ## Output format: terminal, json, or sarif.
    property format : String
    ## Per-rule configuration overrides keyed by rule ID.
    property rules : Hash(String, RuleConfig)
    ## Glob patterns for files to ignore.
    property ignore : Array(String)
    ## Source paths to analyze.
    property paths : Array(String)

    ## Return default config with sensible defaults.
    def self.default : Config
      Config.from_yaml(%(
        severity: warning
        format: terminal
      ))
    rescue
      Config.from_yaml("")
    end

    ## Load config from YAML file path. Fallback to default if missing.
    def self.load(path : String = ".catalyst.yml") : Config
      if File.exists?(path)
        from_yaml(File.read(path))
      else
        default
      end
    end
  end

  ## Delegating loader for config resolution.
  class ConfigLoader
    ## Load config from given path.
    def self.load(path : String) : Config
      Config.load(path)
    end
  end
end

require "yaml"

module Catalyst
  struct RuleConfig
    include YAML::Serializable
    property enabled : Bool = true
    property severity : String? = nil
  end

  struct Config
    include YAML::Serializable

    property severity : String
    property format : String
    property rules : Hash(String, RuleConfig)
    property ignore : Array(String)
    property paths : Array(String)

    def self.default : Config
      Config.from_yaml(%(
        severity: warning
        format: terminal
      ))
    rescue
      Config.from_yaml("") # fallback — should not happen
    end

    def self.load(path : String = ".catalyst.yml") : Config
      if File.exists?(path)
        from_yaml(File.read(path))
      else
        default
      end
    end
  end

  class ConfigLoader
    def self.load(path : String) : Config
      Config.load(path)
    end
  end
end

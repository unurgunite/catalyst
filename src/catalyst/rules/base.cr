require "json"

module Catalyst
  ## Base class for all performance rules.
  ##
  ## Subclasses must implement `#id`, `#severity`, `#description`, and `#check`.
  ## Register rules via `register` in `Macro` or at class load time.
  abstract class Rule
    ## Registry of all loaded rule instances.
    class_getter all : Array(Rule) = [] of Rule

    ## Unique rule identifier (e.g. "CAT-001").
    abstract def id : String

    ## Default severity: error, warning, info, or hint.
    abstract def severity : String

    ## Human-readable description of the anti-pattern.
    abstract def description : String

    ## Whether this rule is enabled by default. Override to disable.
    def enabled_by_default? : Bool
      true
    end

    ## Confidence level: low, medium, or high. Override if needed.
    def confidence : String
      "medium"
    end

    ## Whether this rule supports auto-fix. Override if `#fix` implemented.
    def auto_fixable? : Bool
      false
    end

    ## Called once per file before AST traversal.
    ## Override to set up per-file state.
    def setup(file_path : String, source : String) : Nil
    end

    ## Called for each AST node. Return findings.
    abstract def check(node : Crystal::ASTNode, context : Context) : Array(Result)

    ## Override to provide auto-fix source replacement.
    def fix(node : Crystal::ASTNode) : String?
      nil
    end

    ## Register this rule in the global registry `Rule.all`.
    protected def register
      Rule.all << self
    end
  end

  ## Finding produced by a rule. Includes location, message, and suggestion.
  struct Result
    include JSON::Serializable

    ## Rule ID that produced this finding.
    property rule_id : String
    ## Severity: error, warning, info, or hint.
    property severity : String
    ## Description of the finding.
    property message : String
    ## Source file path.
    property file : String
    ## Line number (1-based).
    property line : Int32
    ## Column number (1-based).
    property column : Int32
    ## Optional suggestion for fixing the issue.
    property suggestion : String?
    ## Confidence: low, medium, or high.
    property confidence : String

    def initialize(
      @rule_id : String,
      @severity : String,
      @message : String,
      @file : String = "",
      @line : Int32 = 0,
      @column : Int32 = 0,
      @suggestion : String? = nil,
      @confidence : String = "medium"
    )
    end
  end

  ## Context passed to rules during AST traversal.
  struct Context
    ## Current source file path.
    getter file : String
    ## Full source code of the file.
    getter source : String
    ## Source code split into lines.
    getter lines : Array(String)

    def initialize(@file : String, @source : String)
      @lines = source.lines
    end

    ## Return the source text at given line number (1-based).
    def line_text(lineno : Int32) : String
      return "" if lineno < 1 || lineno > lines.size
      lines[lineno - 1]
    end
  end
end

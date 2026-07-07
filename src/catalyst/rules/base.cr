require "json"

module Catalyst
  abstract class Rule
    class_getter all : Array(Rule) = [] of Rule

    abstract def id : String
    abstract def severity : String
    abstract def description : String

    def enabled_by_default? : Bool
      true
    end

    def confidence : String
      "medium"
    end

    def auto_fixable? : Bool
      false
    end

    # Called once per file before AST traversal
    def setup(file_path : String, source : String) : Nil
    end

    # Called for each AST node. Return findings.
    abstract def check(node : Crystal::ASTNode, context : Context) : Array(Result)

    # Override to provide auto-fix source replacement
    def fix(node : Crystal::ASTNode) : String?
      nil
    end

    protected def register
      Rule.all << self
    end
  end

  struct Result
    include JSON::Serializable

    property rule_id : String
    property severity : String
    property message : String
    property file : String
    property line : Int32
    property column : Int32
    property suggestion : String?
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

  struct Context
    getter file : String
    getter source : String
    getter lines : Array(String)

    def initialize(@file : String, @source : String)
      @lines = source.lines
    end

    def line_text(lineno : Int32) : String
      return "" if lineno < 1 || lineno > lines.size
      lines[lineno - 1]
    end
  end
end

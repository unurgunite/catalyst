require "json"

module Catalyst
  # # Base class for all performance rules.
  ##
  # # Subclasses must implement `#id`, `#severity`, `#description`, and `#check`.
  # # Register rules via `register` in `Macro` or at class load time.
  abstract class Rule
    # # Registry of all loaded rule instances.
    class_getter all : Array(Rule) = [] of Rule

    # # Unique rule identifier (e.g. "CAT-001").
    abstract def id : String

    # # Default severity: error, warning, info, or hint.
    abstract def severity : String

    # # Human-readable description of the anti-pattern.
    abstract def description : String

    # # Whether this rule is enabled by default. Override to disable.
    def enabled_by_default? : Bool
      true
    end

    # # Confidence level: low, medium, or high. Override if needed.
    def confidence : String
      "medium"
    end

    # # Whether this rule supports auto-fix. Override if `#fix` implemented.
    def auto_fixable? : Bool
      false
    end

    # # Apply config `params` for this rule. Override to read tuning values
    # # from `rules: {CAT-004: {params: {limit: 16}}}`.
    # # Unknown keys are ignored; invalid values fall back to the default.
    def configure(params : Hash(String, YAML::Any)) : Nil
    end

    # # Read an integer param, falling back to `default` when absent or junk.
    protected def int_param(params : Hash(String, YAML::Any), key : String, default : Int32) : Int32
      value = params[key]?
      return default unless value
      value.as_i? || default
    rescue
      default
    end

    # # Called once per file before AST traversal.
    # # Override to set up per-file state.
    def setup(file_path : String, source : String) : Nil
    end

    # # Called for each AST node. Return findings.
    abstract def check(node : Crystal::ASTNode, context : Context) : Array(Result)

    # # Called after visiting all children of a node.
    # # Override to clean up per-node state.
    def end_visit(node : Crystal::ASTNode) : Nil
    end

    # # Override to provide auto-fix source replacement.
    def fix(node : Crystal::ASTNode) : String?
      nil
    end

    # # Replace `pattern` with `replacement` in a source line, but only in
    # # code: occurrences inside string literals or comments are left alone.
    ##
    # # Returns nil when the pattern does not occur in code, so callers never
    # # produce a no-op fix. A rewrite limited to code means a line such as
    # # `puts "sort.first" # see sort.first` keeps both literals intact.
    protected def sub_code(line : String, pattern : Regex | String, replacement : String) : String?
      regex = pattern.is_a?(Regex) ? pattern : Regex.new(Regex.escape(pattern))
      masked = mask_literals(line)
      matched = masked.match(regex, masked.index(regex) || 0)
      return nil unless matched
      line[0...matched.begin(0)] + replacement + line[matched.end(0)..]
    end

    # # Like `#sub_code`, but requires exactly one occurrence in code.
    # # Ambiguous lines get no fix rather than an arbitrary one.
    protected def sub_code_once(line : String, pattern : Regex | String, replacement : String) : String?
      first = sub_code(line, pattern, replacement)
      return nil unless first
      # A second occurrence in the rewritten line means the original had two.
      return nil if sub_code(first, pattern, replacement)
      first
    end

    # # Blank out string-literal and comment contents, preserving length and
    # # offsets so indexes into the result are valid in the original line.
    private def mask_literals(line : String) : String
      chars = line.chars
      i = 0
      while i < chars.size
        i = mask_at(chars, i)
      end
      chars.join
    end

    # Mask whatever starts at `i`, returning the index to continue from.
    private def mask_at(chars : Array(Char), i : Int32) : Int32
      case chars[i]
      when '#'
        # A `#{` inside a string is consumed by the string branch below;
        # reaching `#` here means the rest of the line is a comment.
        (i...chars.size).each { |j| chars[j] = ' ' }
        chars.size
      when '\''
        mask_quoted(chars, i, '\'')
      when '"'
        mask_quoted(chars, i, '"')
      else
        i + 1
      end
    end

    # Mask a single- or double-quoted literal starting at `start`, returning
    # the index just past its closing quote.
    private def mask_quoted(chars : Array(Char), start : Int32, quote : Char) : Int32
      j = start + 1
      while j < chars.size
        if chars[j] == '\\'
          j += 2
          next
        end
        if chars[j] == quote
          mask_span(chars, start, j)
          return j + 1
        end
        j += 1
      end
      # Unterminated on this line (multi-line string / heredoc): mask to EOL.
      mask_span(chars, start, chars.size - 1)
      chars.size
    end

    private def mask_span(chars : Array(Char), from : Int32, to : Int32) : Nil
      (from..to).each { |k| chars[k] = ' ' if k >= 0 && k < chars.size }
    end

    # # Register this rule in the global registry `Rule.all`.
    protected def register
      Rule.all << self
    end
  end

  # # Finding produced by a rule. Includes location, message, and suggestion.
  struct Result
    include JSON::Serializable

    # # Rule ID that produced this finding.
    property rule_id : String
    # # Severity: error, warning, info, or hint.
    property severity : String
    # # Description of the finding.
    property message : String
    # # Source file path.
    property file : String
    # # Line number (1-based).
    property line : Int32
    # # Column number (1-based).
    property column : Int32
    # # Optional suggestion for fixing the issue.
    property suggestion : String?
    # # Confidence: low, medium, or high.
    property confidence : String
    # # Optional replacement text for entire line when auto-fixing.
    property fix_replacement : String?

    def initialize(
      @rule_id : String,
      @severity : String,
      @message : String,
      @file : String = "",
      @line : Int32 = 0,
      @column : Int32 = 0,
      @suggestion : String? = nil,
      @confidence : String = "medium",
      @fix_replacement : String? = nil,
    )
    end
  end

  # # Context passed to rules during AST traversal.
  struct Context
    # # Current source file path.
    getter file : String
    # # Full source code of the file.
    getter source : String
    # # Source code split into lines.
    getter lines : Array(String)

    def initialize(@file : String, @source : String)
      @lines = source.lines
    end

    # # Return the source text at given line number (1-based).
    def line_text(lineno : Int32) : String
      return "" if lineno < 1 || lineno > lines.size
      lines[lineno - 1]
    end
  end
end

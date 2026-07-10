# Catalyst

Static performance analysis for Crystal.

Detects allocation anti-patterns, algorithmic complexity issues, and resource leaks before they reach production. Like
Fasterer for Crystal.

* [Catalyst](#catalyst)
    * [Installation](#installation)
    * [Usage](#usage)
    * [Configuration](#configuration)
    * [Rules](#rules)
    * [Development](#development)
    * [License](#license)

## Installation

```bash
git clone https://github.com/unurgunite/catalyst
cd catalyst
crystal build src/catalyst.cr --release -o bin/catalyst
```

## Usage

```bash
# Scan a directory recursively
catalyst src/

# Scan specific files
catalyst src/app.cr src/lib.cr

# CI mode — exit code 1 on findings
catalyst --ci src/

# JSON output
catalyst --format json src/

# Apply safe auto-fixes
catalyst --fix src/

# Enable only specific rules
catalyst --rules CAT-001,CAT-002 src/

# List all rules
catalyst --list-rules
```

## Configuration

Create `.catalyst.yml` in project root:

```yaml
severity: warning
format: terminal

rules:
  CAT-001:
    severity: error

ignore:
  - lib/**
  - "**/*_spec.cr"

paths:
  - src/
```

## Rules

| ID      | Rule                                  | Severity | Fix |
|---------|---------------------------------------|----------|-----|
| CAT-001 | sort.first → min/max                  | warning  | ✅   |
| CAT-002 | map{}.sum → sum{}                     | warning  | ✅   |
| CAT-003 | select + reject → partition           | info     | ❌   |
| CAT-004 | Array#include? in loop → Set          | warning  | ❌   |
| CAT-005 | shift/unshift → Deque                 | info     | ❌   |
| CAT-006 | hash.keys.each → each_key             | info     | ✅   |
| CAT-007 | reverse.each → reverse_each           | hint     | ✅   |
| CAT-008 | select.first/last → find              | warning  | ✅   |
| CAT-009 | group_by for counters                 | info     | ❌   |
| CAT-010 | String#+ in loop → String.build       | warning  | ❌   |
| CAT-011 | Multi-pass gsub                       | hint     | ❌   |
| CAT-012 | JSON.parse → Serializable             | info     | ❌   |
| CAT-013 | TCPSocket resource leak               | error    | ❌   |
| CAT-014 | File.read → streaming                 | info     | ✅   |
| CAT-015 | Struct vs Class heuristic             | info     | ❌   |
| CAT-016 | Large union types                     | info     | ❌   |
| CAT-017 | Time.local → Time.utc                 | hint     | ✅   |
| CAT-018 | String#downcase == → compare          | hint     | ✅   |
| CAT-019 | Regex.new in loop → constant          | warning  | ✅   |
| CAT-020 | IO::Memory for unread output          | warning  | ✅   |
| CAT-021 | values.each → each_value              | info     | ❌   |
| CAT-022 | shuffle.first → sample                | info     | ❌   |
| CAT-023 | includes? on String → char comparison | info     | ❌   |
| CAT-024 | keys/values.map → each_key/each_value | info     | ❌   |
| CAT-025 | File.open resource leak               | error    | ❌   |
| CAT-026 | Dir.open resource leak                | error    | ❌   |
| CAT-027 | Tempfile resource leak                | error    | ❌   |
| CAT-028 | HTTP::Client resource leak            | error    | ❌   |
| CAT-029 | DB.open resource leak                 | error    | ❌   |
| CAT-030 | keys.includes? → has_key?             | info     | ❌   |
| CAT-031 | values.includes? → has_value?         | info     | ❌   |
| CAT-032 | split.first → split_limit             | info     | ❌   |
| CAT-033 | select.map → single-pass              | warning  | ❌   |
| CAT-034 | each_with_index.map → map_with_index  | info     | ❌   |
| CAT-035 | split("") → each_char                 | hint     | ❌   |
| CAT-036 | chars.each → each_char                | info     | ❌   |
| CAT-037 | Logging with block form               | info     | ❌   |
| CAT-038 | Capacity hints for large collections  | info     | ❌   |
| CAT-039 | Regex.new in method → constant        | warning  | ❌   |
| CAT-040 | String.build for simple literals      | hint     | ❌   |
| CAT-041 | Parsing to constant                   | hint     | ❌   |
| CAT-042 | sleep(0) → Fiber.yield                | hint     | ❌   |
| CAT-043 | Random.new reuse                      | info     | ❌   |
| CAT-044 | ** power → Math.pow                   | info     | ❌   |
| CAT-046 | reverse.reverse no-op                 | hint     | ❌   |
| CAT-047 | upcase.downcase / downcase.upcase no-op | hint   | ❌   |
| CAT-048 | puts to_s redundant                   | hint     | ❌   |
| CAT-049 | Thread.new → spawn                    | warning  | ❌   |
| CAT-050 | Fiber.new → spawn                     | warning  | ❌   |

## Development

```bash
crystal spec
catalyst src/
ameba src/
```

## License

MIT

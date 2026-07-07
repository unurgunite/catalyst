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

| ID      | Rule                            | Severity | Fix |
|---------|---------------------------------|----------|-----|
| CAT-001 | sort.first → min/max            | warning  | ✅   |
| CAT-002 | map{}.sum → sum{}               | warning  | ✅   |
| CAT-003 | select + reject → partition     | info     | ✅   |
| CAT-004 | Array#include? in loop → Set    | warning  | ❌   |
| CAT-005 | shift/unshift → Deque           | info     | ❌   |
| CAT-006 | hash.keys.each → each_key       | info     | ✅   |
| CAT-007 | reverse.each → reverse_each     | hint     | ✅   |
| CAT-008 | select.first/last → find        | warning  | ✅   |
| CAT-009 | group_by for counters           | info     | ❌   |
| CAT-010 | String#+ in loop → String.build | warning  | ❌   |
| CAT-011 | Multi-pass gsub                 | hint     | ❌   |
| CAT-012 | JSON.parse → Serializable       | info     | ❌   |
| CAT-013 | TCPSocket resource leak         | error    | ❌   |
| CAT-014 | File.read → streaming           | info     | ✅   |
| CAT-015 | Struct vs Class heuristic       | info     | ❌   |
| CAT-016 | Large union types               | info     | ❌   |
| CAT-017 | Time.local → Time.utc           | hint     | ✅   |
| CAT-018 | downcase == → compare           | hint     | ✅   |
| CAT-019 | Regex.new in loop → constant    | warning  | ✅   |
| CAT-020 | IO::Memory for unread output    | warning  | ✅   |

## Development

```bash
crystal spec
catalyst src/
ameba src/
```

## License

MIT

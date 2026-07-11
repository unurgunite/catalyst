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

All 49 rules (CAT-001–CAT-050, except CAT-045) are documented in the [Wiki](https://github.com/unurgunite/catalyst/wiki).

Quick reference:
```bash
catalyst --list-rules
```

## Development

```bash
crystal spec
catalyst src/
ameba src/
```

## License

MIT

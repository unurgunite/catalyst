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

# Only show findings at or above a severity
catalyst --severity error src/

# Apply safe auto-fixes
catalyst --fix src/

# See what --fix would change, without writing
catalyst --fix --dry-run src/

# Enable only specific rules
catalyst --rules CAT-001,CAT-002 src/

# Gate on new findings only (baseline workflow)
catalyst --update-baseline .catalyst-baseline.json src/
catalyst --baseline .catalyst-baseline.json --ci src/

# List all rules
catalyst --list-rules
```

`--format` and `--severity` override the values from `.catalyst.yml`.

Exit codes: `0` clean, `1` findings in `--ci` mode, `2` configuration or
runtime error.

### Auto-fix safety

`--fix` never writes a file it cannot re-parse: every rewritten file is
parsed before it is saved, and any fix whose result would not parse is
skipped with a diagnostic on STDERR. A finding whose replacement equals the
original line is treated as a no-op. The original file is copied to
`<file>.bak` **before the first** fix and an existing `.bak` is never
overwritten, so a re-run cannot clobber the only pre-fix copy — delete or
move the `.bak` yourself once you have reviewed the change. Use `--dry-run`
to preview. Diagnostics always go to STDERR, so `--format json` and
`--format sarif` output stays machine-readable on STDOUT.

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

`lib/**` keeps vendored shards out of the report: on real projects they
accounted for the large majority of findings, and none of them are yours to
fix. `**/*_spec.cr` does the same for test files — a spec that opens a
socket on purpose is usually not a leak — though that one is a judgment
call, so it is opt-in rather than built in.

## Rules

All 46 rules are documented in the [Wiki](https://github.com/unurgunite/catalyst/wiki). Numbers are not contiguous: CAT-036, 040, 044, 046, 047 and 048 were removed, and their numbers stay retired so an old `ignore` entry still means what it did.

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

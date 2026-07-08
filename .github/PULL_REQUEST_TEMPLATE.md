## Description

What does this PR do?

## Reproduction

Minimal Crystal code that triggers the rule:

```crystal
# Example
```

## Expected output

```
# catalyst --format terminal output
```

## Checklist

- [ ] Tests pass (`crystal spec`)
- [ ] Formatting clean (`crystal tool format --check`)
- [ ] Lint clean (`crystal run bin/ameba.cr --`)
- [ ] Binary builds (`crystal build src/catalyst.cr --release -o bin/catalyst`)
- [ ] Branch name follows convention (`feature/*`)

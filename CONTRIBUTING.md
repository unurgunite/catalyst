# Contributing

## Adding a New Rule

1. Pick next available ID from board (CAT-NNN).
2. Create rule file `src/catalyst/rules/<snake_name>.cr`.
3. Create spec file `spec/catalyst/rules/<snake_name>_spec.cr`.
4. Create bench file `bench/cat-NNN/bench_<snake_name>.cr`.
5. Run `crystal scripts/generate_rules_require.cr` to regenerate requires (or just run `crystal spec` — macro auto-generates).
6. Verify: `crystal spec && crystal tool format --check && crystal run bin/ameba.cr -- && crystal build src/catalyst.cr --release -o bin/catalyst`.

## Rule File Template

```crystal
module Catalyst
  module Rules
    class MyNewRule < Rule
      def id : String
        "CAT-NNN"
      end

      def severity : String
        "warning"
      end

      def description : String
        "Short description of the anti-pattern"
      end

      def check(node : Crystal::ASTNode, context : Context) : Array(Result)
        [] of Result
      end

      Rule.all << self.new
    end
  end
end
```

Required methods: `id`, `severity`, `description`, `check`. Register with `Rule.all << self.new` at class load time.

## Spec File Pattern

```crystal
require "../../spec_helper"

module Catalyst
  module Rules
    describe MyNewRule do
      rule = MyNewRule.new

      describe "#check" do
        it "detects the pattern" do
          assert_finding(rule, "code.that.triggers")
        end

        it "ignores optimal code" do
          assert_no_finding(rule, "code.that.is.fine")
        end
      end
    end
  end
end
```

Helpers from `spec_helper.cr`:
- `assert_finding(rule, code, count = 1)` — expects exactly `count` findings
- `assert_no_finding(rule, code)` — expects zero findings

## Bench File Pattern

```crystal
require "benchmark"

[10, 100, 1_000, 10_000, 100_000].each do |n|
  # setup data of size n
  old = Benchmark.measure { /* anti-pattern */ }
  new = Benchmark.measure { /* optimized */ }
  ratio = old.real / new.real
  puts "n=#{n.to_s.ljust(6)}  old=#{old.real.round(6)}s  new=#{new.real.round(6)}s  #{ratio.round(2)}x faster"
end
```

## Code Style

- Run `crystal tool format` before committing.
- No comments in rule/spec/bench code (only doc comments for public API).
- Follow existing conventions: filenames snake_case, class names PascalCase.

## PR Process

1. Branch from `v0.2.x`:

   ```
   git checkout v0.2.x
   git pull origin v0.2.x
   git checkout -b feature/<short-description>
   ```

2. Implement rule + spec + bench.
3. Commit:

   ```
   git add -A
   git commit -m "[0.2.x] Short description"
   ```

4. Push and create PR:

   ```
   git push -u origin feature/<short-description>
   gh pr create --base v0.2.x --fill --label rules
   ```

5. PR description template:

   ```
   ## Description

   What this PR adds.

   ## Reproduction

   ```crystal
   # Minimal code that triggers the rule
   ```

   ## Expected output

   ```
   $ catalyst --format terminal src/example.cr
   ... warning output ...
   ```

   ## Performance (macOS ARM, Crystal <version>)

   ```
   n=10:     X.XXx faster
   n=100:    X.XXx
   n=1000:   X.XXx
   n=10000:  X.XXx
   n=100000: X.XXx
   ```

   Run: `crystal run bench/cat-NNN/bench_<rule_name>.cr`

   ## Checklist

   - [ ] Tests pass (`crystal spec`)
   - [ ] Formatting clean (`crystal tool format --check`)
   - [ ] Lint clean (`crystal run bin/ameba.cr --`)
   - [ ] Binary builds (`crystal build src/catalyst.cr --release -o bin/catalyst`)
   - [ ] Branch name follows convention (`feature/<short-description>`)
   ```

## Verification Checklist

- `crystal spec` — all tests pass
- `crystal tool format --check` — formatting clean
- `crystal run bin/ameba.cr --` — no lint issues
- `crystal build src/catalyst.cr --release -o bin/catalyst` — binary builds

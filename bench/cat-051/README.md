# CAT-051: Bound fiber fan-out (`N.times { spawn }` x semaphore permits)

A worker pool shaped as `FIBERS.times { spawn { ... } }` gated by a
`Channel(Nil)` counting semaphore can starve the fiber thread pool when the
product of fibers × permits grows unchecked. CAT-051 multiplies the two
sides and flags products over `FAN_OUT_THRESHOLD = 1000`:

- both sides resolve to ints and the product exceeds 1000 → `warning`/`medium`
  with F×P=N in the message (constant folding for `X = <int>` in the same file);
- the `times → spawn` + `Channel(Nil)` shape matches but an operand comes from
  config/CLI/args (invisible statically) → single `info`/`low` per file:
  verify F×P ≤ 1000;
- producers, collectors, prefills, `each` without spawn, bare `spawn`,
  resolved products ≤ 1000, non-`Nil` channels → silent.

## Verification (not a microbenchmark)

Fan-out detection has no meaningful microbenchmark — there is no
"before/after" timing to measure. Verification is detection on fixtures:

- `50.times + Channel(Nil).new(100)` → 1 finding, message shows the product;
- `8.times + Channel(Nil).new(8)` → silent (64 ≤ 1000);
- config-sourced operands → 1 `info`/`low` hint per file;
- task queues (`Channel(String).new(1024)`), bare `spawn`, producers → silent.

E2E: `info`/`low` hints on config-driven fan-out shapes,
zero on catalyst's own `src/`.

## Run

`crystal spec spec/catalyst/rules/spawn_fan_out_spec.cr`

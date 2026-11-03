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

## Benchmark

`bench_spawn_fan_out.cr` measures what the recommendation costs: an unbounded
`fibers.times { spawn }` burst versus the same work through a
`Channel(Nil)`-gated pool of 8 permits. The gate is the fix CAT-051 asks for,
and it is not free — it serialises admission.

## Run

`crystal spec spec/catalyst/rules/spawn_fan_out_spec.cr`
`crystal run bench/cat-051/bench_spawn_fan_out.cr`

# CAT-052: Avoid blocking calls inside `spawn` workers

A worker fiber that blocks on `Process.new` (subprocess), a raw socket, or a
bare `sleep` holds an event-loop thread while doing nothing. At fan-out this
starves the fiber thread pool.

Three detection levels, all `warning`/`medium` (never `error` — a timeout
around the call is invisible statically):

1. Blocking primitives lexically inside `spawn` (`Process.new`/`run`,
   `sleep N`/`N.seconds` with N > 0, `HTTP::Client` requests, `system`,
   backticks).
2. Worker-wrapper calls (`check_config`, `tcp_alive?`, `fetch_ip`,
   `handle_failover`, …) lexically inside `spawn`.
3. Blocking primitives inside a `def`/lambda statically called from `spawn`
   (depth ≤ 3, forward references and `->(){}.call` lambdas resolved).

Skips: `TCPSocket.new` (CAT-013 already errors), `sleep 0` (CAT-042 yield
idiom), non-literal `sleep` args (unknown).

## Benchmark

`bench_blocking_call_in_spawn.cr` measures event-loop time, which is the cost
this rule is about: a blocking `sleep 20.ms` inside `spawn` versus the same
wall-clock wait made of `Fiber.yield` calls, plus a heartbeat fiber whose tick
rate reveals how much loop time the blocking calls ate. The spec's 20 fixtures
cover detection; this script covers the claim that detection is worth having.

## Run

`crystal spec spec/catalyst/rules/blocking_call_in_spawn_spec.cr`
`crystal run bench/cat-052/bench_blocking_call_in_spawn.cr`

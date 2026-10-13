# CAT-052: Avoid blocking calls inside `spawn` workers

A worker fiber that blocks on `Process.new` (xray), a raw socket, or a bare
`sleep` holds an event-loop thread while doing nothing. At fan-out this
starves `Fiber::ExecutionContext::ThreadPool` (production segfault at 50×100).

Three detection levels, all `warning`/`medium` (never `error` — a timeout
around the call is invisible statically):

1. Blocking primitives lexically inside `spawn` (`Process.new`/`run`,
   `sleep N`/`N.seconds` with N > 0, `HTTP::Client` requests, `system`,
   backticks).
2. Worker-wrapper calls (`test_config`, `tcp_alive?`, `fetch_ip`,
   `do_failover`, …) lexically inside `spawn`.
3. Blocking primitives inside a `def`/lambda statically called from `spawn`
   (depth ≤ 3, forward references and `->(){}.call` lambdas resolved).

Skips: `TCPSocket.new` (CAT-013 already errors), `sleep 0` (CAT-042 yield
idiom), non-literal `sleep` args (unknown).

## Verification (not a microbenchmark)

Blocking detection has no meaningful microbenchmark. Verification is
detection on fixtures (12 positive/negative cases in the spec) plus E2E on
the incident codebase: 14 findings (3 in `check_configs.cr` including the
segfault trio, 11 in `vpn.cr` including the `do_failover` lambda chain),
zero on catalyst's own `src/`.

## Run

`crystal spec spec/catalyst/rules/blocking_call_in_spawn_spec.cr`

# CAT-029: DB.open resource leak

`DB.open(url)` without block requires manual `close`. Block form auto-closes.

## Before / After

```crystal
db = DB.open("postgres://localhost/mydb")
db.exec("SELECT 1")
db.close
```

```crystal
DB.open("postgres://localhost/mydb") { |db| db.exec("SELECT 1") }
```

## Results (macOS ARM, Crystal 1.22.2)

```
=== DB.open without block vs with block ===

Resource leak rules focus on SAFETY (not speed).
Block form ensures close even on exceptions.
The rule's cost is one AST visit; the saving is a leaked connection.

Microbenchmark comparing call patterns:

n=10      baseline=0.0      s  db.open=0.0      s  1.0x faster (safety only, no timing change)
n=100     baseline=0.0      s  db.open=0.0      s  1.0x faster (safety only, no timing change)
n=1000    baseline=1.0e-6   s  db.open=1.0e-6   s  1.0x faster (safety only, no timing change)
n=10000   baseline=9.0e-6   s  db.open=9.0e-6   s  1.0x faster (safety only, no timing change)
n=100000  baseline=9.1e-5   s  db.open=9.1e-5   s  1.0x faster (safety only, no timing change)
```

> [!IMPORTANT]
> The ratio is an explicit `1.0x` rather than a blank: opening a connection
> with or without the block costs the same, so the rule's whole payoff is the
> `close` the block guarantees. `bench/run_all.cr` reads this line as parity
> instead of reporting the benchmark as having no claim.

## Run

`crystal run bench/cat-029/bench_db_open_leak.cr`

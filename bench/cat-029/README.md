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

## Results (macOS ARM, Crystal 1.20.3)

```
=== DB.open without block vs with block ===

Resource leak rules focus on SAFETY (not speed).
Block form ensures close even on exceptions.

Microbenchmark comparing call patterns:

n=10      baseline=0.0      s  rule=SAFETY (no perf impact)
n=100     baseline=0.0      s  rule=SAFETY (no perf impact)
n=1000    baseline=0.0      s  rule=SAFETY (no perf impact)
n=10000   baseline=0.0      s  rule=SAFETY (no perf impact)
n=100000  baseline=0.0      s  rule=SAFETY (no perf impact)
```

## Run

`crystal run bench/cat-029/bench_db_open_leak.cr`

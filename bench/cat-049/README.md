# CAT-049: Use `spawn` instead of `Thread.new`

`Thread.new` creates an OS thread. `spawn` creates a lightweight fiber on the event loop. Use `spawn` unless true parallelism is needed.

## Before / After

```crystal
Thread.new { do_work }

# ↓

spawn { do_work }
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== Thread.new vs spawn ===
n=10      Thread.new=0.000332 s  spawn=3.1e-5   s  10.75x faster
n=100     Thread.new=0.001403 s  spawn=0.000225 s  6.23x faster
n=1000    Thread.new=0.012475 s  spawn=0.00201  s  6.21x faster
```

## Run

`crystal run bench/cat-049/bench_thread_new_to_spawn.cr`

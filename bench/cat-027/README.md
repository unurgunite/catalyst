# CAT-027: Tempfile resource leak

`Tempfile.new(name)` without block requires manual `close`. Block form auto-closes.

## Before / After

```crystal
f = Tempfile.new("data")
f.puts "hello"
f.close
```

```crystal
Tempfile.new("data") { |f| f.puts "hello" }
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== Tempfile.new vs Tempfile.open block (microbenchmark) ===

n=10      manual=0.000828 s  block=0.000568 s  1.46x faster
n=100     manual=0.005711 s  block=0.00449  s  1.27x faster
n=1000    manual=0.076081 s  block=0.057285 s  1.33x faster
```

## Run

`crystal run bench/cat-027/bench_tempfile_leak.cr`

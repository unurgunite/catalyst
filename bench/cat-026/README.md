# CAT-026: Dir.open resource leak

`Dir.open(path)` without block requires manual `close`. Block form auto-closes.

## Before / After

```crystal
d = Dir.open(".")
d.entries
d.close
```

```crystal
Dir.open(".") { |d| d.entries }
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== Dir.open vs Dir.open with block ===

n=10      manual=0.000102 s  block=7.8e-5   s  1.3x faster
n=100     manual=0.000664 s  block=0.000624 s  1.06x faster
n=1000    manual=0.005754 s  block=0.005796 s  0.99x faster
n=10000   manual=0.060458 s  block=0.061427 s  0.98x faster
n=100000  manual=0.594606 s  block=0.623934 s  0.95x faster
```

## Run

`crystal run bench/cat-026/bench_dir_open_leak.cr`

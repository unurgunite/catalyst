# CAT-025: File.open resource leak

`File.open(path)` without block requires manual `close`. Block form auto-closes.

## Before / After

```crystal
f = File.open("file.txt")
f.gets
f.close
```

```crystal
File.open("file.txt") { |f| f.gets }
```

## Results (macOS ARM, Crystal 1.20.3)

```

=== File.open vs File.open with block (microbenchmark) ===

n=10      manual=0.000172 s  block=9.0e-5   s  1.91x faster
n=100     manual=0.000889 s  block=0.000763 s  1.16x faster
n=1000    manual=0.007029 s  block=0.006703 s  1.05x faster
n=10000   manual=0.068794 s  block=0.070376 s  0.98x faster
n=100000  manual=0.701708 s  block=0.686076 s  1.02x faster
```

## Run

`crystal run bench/cat-025/bench_file_open_leak.cr`

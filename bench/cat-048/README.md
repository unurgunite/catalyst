# CAT-048: Remove redundant .to_s in puts/print/STDOUT calls

`puts`, `print`, and `write` already call `to_s` on their arguments.

## Before / After

```crystal
puts obj.to_s  # → puts obj
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      to_s=8.3e-7s    direct=9.6e-7s    0.87x faster
n=100     to_s=5.33e-6s   direct=3.88e-6s   1.38x faster
n=1000    to_s=2.483e-5s  direct=2.392e-5s  1.04x faster
n=10000   to_s=0.00022488s direct=0.00021625s 1.04x faster
n=100000  to_s=0.00222817s direct=0.00217404s 1.02x faster
```

Note: The compiler often optimizes away redundant `to_s` calls. The primary
benefit is code clarity rather than performance.
```

## Run

`crystal run bench/cat-048/bench_puts_to_s_redundant.cr`

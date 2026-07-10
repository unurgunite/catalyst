# CAT-046: Remove redundant reverse.reverse chain

`reverse.reverse` returns the original collection unchanged but allocates intermediate arrays.

## Before / After

```crystal
arr.reverse.reverse  # → arr
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      reverse.reverse=7.667e-5s  direct=3.8e-7s     204.45x faster
n=100     reverse.reverse=0.00076725s direct=5.8e-7s    1316.04x faster
n=1000    reverse.reverse=0.00660667s direct=1.25e-6s   5285.33x faster
n=10000   reverse.reverse=0.07309958s direct=9.37e-6s   7797.29x faster
n=100000  reverse.reverse=0.76954392s direct=2.608e-5s  29503.66x faster
```

## Run

`crystal run bench/cat-046/bench_reverse_reverse_noop.cr`

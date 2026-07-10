# CAT-038: Pre-size collections with capacity hints

`Array(Type).new` without capacity causes repeated reallocations as elements are appended. Pre-sizing with `Array(Type).new(n)` when size is known avoids this.

## Before / After

```crystal
arr = [] of Int32
n.times { arr << i }

# ↓

arr = Array(Int32).new(n)
n.times { arr << i }
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== Array.new vs Array.new(capacity) ===
n=10      no_cap=7.0e-6   s  with_cap=4.0e-6   s  1.97x faster
n=100     no_cap=4.7e-5   s  with_cap=2.4e-5   s  1.99x faster
n=1000    no_cap=0.000409 s  with_cap=0.000211 s  1.94x faster
n=10000   no_cap=0.003245 s  with_cap=0.001743 s  1.86x faster
n=100000  no_cap=0.031447 s  with_cap=0.020608 s  1.53x faster
```

## Run

`crystal run bench/cat-038/bench_capacity_hints.cr`

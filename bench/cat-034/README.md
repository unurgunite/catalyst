# CAT-034: Use `map_with_index` instead of `each_with_index` + `map`

`each_with_index` returns an iterator, then `map` iterates and builds a new array. `map_with_index` combines both in a single pass.

## Before / After

```crystal
arr.each_with_index.map { |x, i| x * i }

# ↓

arr.map_with_index { |x, i| x * i }
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      each_with_index.map=1.0e-6   s  map_with_index=2.0e-6   s  0.5x faster
n=100     each_with_index.map=2.0e-6   s  map_with_index=1.0e-6   s  2.18x faster
n=1000    each_with_index.map=5.0e-6   s  map_with_index=1.0e-6   s  5.29x faster
n=10000   each_with_index.map=3.9e-5   s  map_with_index=7.0e-6   s  5.26x faster
n=100000  each_with_index.map=0.000433 s  map_with_index=3.1e-5   s  14.02x faster
```

## Run

`crystal run bench/cat-034/bench_each_with_index_map_to_map_with_index.cr`

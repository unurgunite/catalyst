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
=== each_with_index.map vs map_with_index ===
n=10      TBD
n=100     TBD
n=1000    TBD
n=10000   TBD
n=100000  TBD
```

## Run

`crystal run bench/cat-034/bench_each_with_index_map_to_map_with_index.cr`

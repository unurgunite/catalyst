# CAT-033: Use `filter_map` instead of `select` + `map`

`select` allocates a filtered intermediate array, then `map` allocates another. `filter_map` does both in a single pass without the intermediate array.

## Before / After

```crystal
arr.select { |x| x.even? }.map { |x| x * 2 }

# ↓

arr.filter_map { |x| x * 2 if x.even? }
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== select{}.map{} vs filter_map{} ===
n=10      TBD
n=100     TBD
n=1000    TBD
n=10000   TBD
n=100000  TBD
```

## Run

`crystal run bench/cat-033/bench_select_map_to_filter_map.cr`

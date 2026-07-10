# CAT-002: Use `sum{}` instead of `map{}.sum`

`map{}.sum` creates an intermediate array for the mapped values. `sum{}` combines both in a single pass, avoiding the allocation.

## Before / After

```crystal
total = arr.map { |x| x * 2 }.sum

# ↓

total = arr.sum { |x| x * 2 }
```

## Run

`crystal run bench/cat-002/bench_map_sum.cr`

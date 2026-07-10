# CAT-001: Use `min`/`max` instead of `sort.first`/`sort.last`

`sort.first` sorts the entire array O(n log n) then takes the first element. `min` finds it in a single O(n) pass.

## Before / After

```crystal
arr.sort.first  # O(n log n), allocates new sorted array
arr.sort.last

# ↓

arr.min  # O(n), no allocation
arr.max
```

## Run

`crystal run bench/cat-001/bench_sort_first.cr`

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

## Results (macOS ARM, Crystal 1.20.3)

```
=== sort.first vs min ===
n=10      sort.first=1.0e-6   s  min=0.0      s  2.67x faster
n=100     sort.first=8.0e-6   s  min=1.0e-6   s  9.29x faster
n=1000    sort.first=9.2e-5   s  min=6.0e-6   s  15.89x faster
n=10000   sort.first=0.001184 s  min=5.6e-5   s  20.98x faster
n=100000  sort.first=0.014924 s  min=0.000596 s  25.05x faster

=== sort.last vs max ===
n=10      sort.last=1.0e-6   s  max=1.0e-6   s  1.93x faster
n=100     sort.last=9.0e-6   s  max=1.0e-6   s  8.18x faster
n=1000    sort.last=0.000108 s  max=7.0e-6   s  14.97x faster
n=10000   sort.last=0.001524 s  max=6.7e-5   s  22.72x faster
n=100000  sort.last=0.01553  s  max=0.000638 s  24.35x faster
```

## Run

`crystal run bench/cat-001/bench_sort_first.cr`

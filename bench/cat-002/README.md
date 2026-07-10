# CAT-002: Use `sum{}` instead of `map{}.sum`

`map{}.sum` creates an intermediate array for the mapped values. `sum{}` combines both in a single pass, avoiding the allocation.

## Before / After

```crystal
total = arr.map { |x| x * 2 }.sum

# ↓

total = arr.sum { |x| x * 2 }
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== map{}.sum vs sum{} (Int64, x * 2) ===
n=10      map{}.sum=1.0e-6   s  sum{}=1.0e-6   s  1.23x faster
n=100     map{}.sum=2.0e-6   s  sum{}=1.0e-6   s  1.48x faster
n=1000    map{}.sum=9.0e-6   s  sum{}=6.0e-6   s  1.53x faster
n=10000   map{}.sum=7.7e-5   s  sum{}=5.5e-5   s  1.4x faster
n=100000  map{}.sum=0.000747 s  sum{}=0.000489 s  1.53x faster

=== With initial value 0_i64 ===
n=10      map{}.sum(0)=0.0      s  sum(0){} =0.0      s  1.38x faster
n=100     map{}.sum(0)=1.0e-6   s  sum(0){} =1.0e-6   s  1.77x faster
n=1000    map{}.sum(0)=7.0e-6   s  sum(0){} =5.0e-6   s  1.63x faster
n=10000   map{}.sum(0)=7.0e-5   s  sum(0){} =4.3e-5   s  1.63x faster
n=100000  map{}.sum(0)=0.000853 s  sum(0){} =0.000458 s  1.86x faster
```

## Run

`crystal run bench/cat-002/bench_map_sum.cr`

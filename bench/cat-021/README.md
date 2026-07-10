# CAT-021: Use `each_value` instead of `values.each`

`hash.values.each` creates a new Array with all values, then iterates. `hash.each_value` iterates directly without
allocation.

## Before / After

```crystal
hash.values.each { |v| puts v }

# ↓

hash.each_value { |v| puts v }
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== hash.values.each vs hash.each_value ===
n=10      values.each=1.0e-6   s  each_value=0.0      s  1.73x faster
n=100     values.each=1.0e-6   s  each_value=1.0e-6   s  0.97x faster
n=1000    values.each=1.0e-5   s  each_value=7.0e-6   s  1.29x faster
n=10000   values.each=7.7e-5   s  each_value=6.0e-5   s  1.27x faster
n=100000  values.each=0.00097  s  each_value=0.000672 s  1.44x faster
```

## Run

`crystal run bench/cat-021/bench_values_each_to_each_value.cr`

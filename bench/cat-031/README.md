# CAT-031: Use `has_value?` instead of `values.includes?`

`hash.values.includes?(v)` creates a new Array with all values then does linear search.
`hash.has_value?(v)` performs direct O(n) value scan without allocation.

## Before / After

```crystal
hash.values.includes?("val")

# ↓

hash.has_value?("val")
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      values.includes?=1.0e-6   s  has_value?=0.0      s  1.86x faster
n=100     values.includes?=8.0e-6   s  has_value?=0.0      s  23.83x faster
n=1000    values.includes?=0.000698 s  has_value?=0.0      s  2090.44x faster
n=10000   values.includes?=0.054566 s  has_value?=0.0      s  163369.76x faster
n=100000  values.includes?=11.669648s  has_value?=0.0      s  35043987.86x faster
```

## Run

`crystal run bench/cat-031/bench_values_includes_to_has_value.cr`

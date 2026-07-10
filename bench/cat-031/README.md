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
=== Hash#values.includes? vs Hash#has_value? ===
```

## Run

`crystal run bench/cat-031/bench_values_includes_to_has_value.cr`

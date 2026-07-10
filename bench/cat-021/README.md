# CAT-021: Use `each_value` instead of `values.each`

`hash.values.each` creates a new Array with all values, then iterates. `hash.each_value` iterates directly without allocation.

## Before / After

```crystal
hash.values.each { |v| puts v }

# ↓

hash.each_value { |v| puts v }
```

## Run

`crystal run bench/cat-021/bench_values_each_to_each_value.cr`

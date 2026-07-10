# CAT-030: Use `has_key?` instead of `keys.includes?`

`hash.keys.includes?(k)` creates a new Array with all keys then does linear search.
`hash.has_key?(k)` performs direct O(1) hash lookup.

## Before / After

```crystal
hash.keys.includes?("key")

# ↓

hash.has_key?("key")
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== Hash#keys.includes? vs Hash#has_key? ===
```

## Run

`crystal run bench/cat-030/bench_keys_includes_to_has_key.cr`

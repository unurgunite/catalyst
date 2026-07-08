# CAT-006: Use `each_key` instead of `keys.each`

`Hash#keys` allocates a new `Array` of all keys. `Hash#each_key` iterates keys directly without allocation.

## Before / After

```crystal
hash.keys.each { |k| puts k }  # → hash.each_key { |k| puts k }
```

## Results (macOS ARM, Crystal 1.20.3)

Paste benchmark output here.

## Run

`crystal run bench/cat-006/bench_hash_keys_each.cr`

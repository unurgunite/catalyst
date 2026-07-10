# CAT-024: Use `each_key.map`/`each_value.map` instead of `keys.map`/`values.map`

`hash.keys.map` allocates a new Array for all keys, then maps over it. `hash.each_key.map` iterates and maps in one pass.

## Before / After

```crystal
hash.keys.map { |k| k.upcase }
hash.values.map { |v| v * 2 }

# ↓

hash.each_key.map { |k| k.upcase }
hash.each_value.map { |v| v * 2 }
```

## Run

`crystal run bench/cat-024/bench_keys_values_map_to_each_kv.cr`

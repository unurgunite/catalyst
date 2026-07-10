# CAT-024: Use `each_key.map`/`each_value.map` instead of `keys.map`/`values.map`

`hash.keys.map` allocates a new Array for all keys, then maps over it. `hash.each_key.map` iterates and maps in one
pass.

## Before / After

```crystal
hash.keys.map { |k| k.upcase }
hash.values.map { |v| v * 2 }

# ↓

hash.each_key.map { |k| k.upcase }
hash.each_value.map { |v| v * 2 }
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== hash.keys.map vs hash.each_key.map ===
n=10      keys.map=1.0e-6   s  each_key.map=0.0      s  2.0x faster
n=100     keys.map=1.0e-6   s  each_key.map=0.0      s  3.78x faster
n=1000    keys.map=1.3e-5   s  each_key.map=0.0      s  37.8x faster
n=10000   keys.map=8.6e-5   s  each_key.map=0.0      s  228.45x faster
n=100000  keys.map=0.000931 s  each_key.map=0.0      s  2482.11x faster

=== hash.values.map vs hash.each_value.map ===
n=10      values.map=1.0e-6   s  each_value.map=1.0e-6   s  1.16x faster
n=100     values.map=2.0e-6   s  each_value.map=0.0      s  4.0x faster
n=1000    values.map=1.1e-5   s  each_value.map=0.0      s  29.33x faster
n=10000   values.map=8.3e-5   s  each_value.map=0.0      s  284.39x faster
n=100000  values.map=0.000943 s  each_value.map=1.0e-6   s  1739.93x faster
```

## Run

`crystal run bench/cat-024/bench_keys_values_map_to_each_kv.cr`

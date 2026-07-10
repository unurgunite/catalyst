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
n=10      keys.includes?=2.0e-6   s  has_key?=0.0      s  3.25x faster
n=100     keys.includes?=2.1e-5   s  has_key?=0.0      s  42.67x faster
n=1000    keys.includes?=0.000994 s  has_key?=1.0e-6   s  722.94x faster
n=10000   keys.includes?=0.082049 s  has_key?=1.0e-5   s  7939.75x faster
n=100000  keys.includes?=61.898839s  has_key?=0.000127 s  485797.33x faster
```

## Run

`crystal run bench/cat-030/bench_keys_includes_to_has_key.cr`

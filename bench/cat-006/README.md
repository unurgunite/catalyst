# CAT-006: Use `each_key` instead of `keys.each`

`Hash#keys` allocates a new `Array` of all keys. `Hash#each_key` iterates keys directly without allocation.

## Before / After

```crystal
hash.keys.each { |k| puts k }  # → hash.each_key { |k| puts k }
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      keys.each=1.0e-6s   each_key=0.0s     1.36x faster
n=100     keys.each=1.0e-6s   each_key=1.0e-6s  1.32x faster
n=1000    keys.each=8.0e-6s   each_key=6.0e-6s  1.22x faster
n=10000   keys.each=7.4e-5s   each_key=6.2e-5s  1.20x faster
n=100000  keys.each=0.000766s each_key=0.00056s 1.37x faster
```

## Run

`crystal run bench/cat-006/bench_hash_keys_each.cr`

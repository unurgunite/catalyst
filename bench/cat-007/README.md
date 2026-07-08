# CAT-007: Use `reverse_each` instead of `reverse.each`

`Array#reverse` allocates a new reversed `Array`. `Array#reverse_each` iterates backwards without allocation.

## Before / After

```crystal
arr.reverse.each { |x| puts x }  # → arr.reverse_each { |x| puts x }
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      1.5x faster
n=100     1.64x faster
n=1000    2.75x faster
n=10000   2.61x faster
n=100000  2.55x faster
```

## Run

`crystal run bench/cat-007/bench_reverse_each.cr`

# CAT-004: Use `Set` instead of `Array#include?` in loops

`Array#includes?` is O(n) per lookup. When checking membership inside a loop, converting to a `Set` first makes each lookup O(1).

## Before / After

```crystal
ary.includes?(x)  # → set.includes?(x)  (with `set = ary.to_set` before the loop)
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      Array#include?=1.0e-6s   Set#include?=2.0e-6s   0.5x faster
n=100     Array#include?=1.7e-5s   Set#include?=1.0e-5s   1.71x faster
n=1000    Array#include?=0.001448s Set#include?=9.2e-5s   15.82x faster
n=10000   Array#include?=0.128951s Set#include?=0.000897s 143.77x faster
n=100000  Array#include?=13.457344s Set#include?=0.01065s 1263.59x faster
```

## Run

`crystal run bench/cat-004/bench_array_include_to_set.cr`

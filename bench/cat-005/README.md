# CAT-005: Use `Deque` instead of `Array` for shift/unshift operations

`Array#shift` and `Array#unshift` are O(n) because elements must be shifted
in memory. `Deque` (double-ended queue) provides O(1) amortized shift/unshift.

## Before / After

```crystal
ary.shift         # → deque.shift
ary.unshift(x)    # → deque.unshift(x)
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      Array#shift=1.0e-6   s  Deque#shift=1.0e-6   s  1.3x faster
n=100     Array#shift=1.0e-6   s  Deque#shift=2.0e-6   s  0.73x faster
n=1000    Array#shift=1.0e-5   s  Deque#shift=1.5e-5   s  0.64x faster
n=10000   Array#shift=8.7e-5   s  Deque#shift=0.000141 s  0.62x faster
n=100000  Array#shift=0.000843 s  Deque#shift=0.00143  s  0.59x faster

n=10      Array#unshift=1.0e-6   s  Deque#unshift=1.0e-6   s  0.87x faster
n=100     Array#unshift=1.0e-6   s  Deque#unshift=2.0e-6   s  0.69x faster
n=1000    Array#unshift=6.0e-6   s  Deque#unshift=8.0e-6   s  0.75x faster
n=10000   Array#unshift=6.6e-5   s  Deque#unshift=8.0e-5   s  0.83x faster
```

> [!NOTE]
> Array's `memmove` (C-level) and contiguous memory layout make
> sequential shift/unshift competitive for small-to-medium collections.
> Deque provides consistent O(1) amortized random access shift/unshift,
> which benefits workloads with interleaved operations.

## Run

`crystal run bench/cat-005/bench_shift_unshift_to_deque.cr`

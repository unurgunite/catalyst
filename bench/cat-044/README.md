# CAT-044: Use `x * x` instead of `x ** 2`, `Math.sqrt` instead of `** 0.5`

Power operator `**` is more general and may not inline as well. `x * x` and `Math.sqrt(x)` are more idiomatic and LLVM can optimize better.

> **Caveat**: Benchmarks show ~1x difference — LLVM optimizes both forms to identical machine code in most cases. This is an **educational/style rule**, not a performance optimisation. Confidence lowered to `low`.

## Before / After

```crystal
x ** 2
x ** 0.5

# ↓

x * x
Math.sqrt(x)
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== x ** 2 vs x * x ===
n=10000000  x**2=3.33e-7     s  x*x=5.0e-7      s  0.67x faster
n=50000000  x**2=4.17e-7     s  x*x=2.91e-7     s  1.43x faster

=== x ** 0.5 vs Math.sqrt(x) ===
n=10000000  x**0.5=4.59e-7     s  sqrt=4.59e-7     s  1.0x faster
n=50000000  x**0.5=2.91e-7     s  sqrt=5.42e-7     s  0.54x faster
```

## Run

`crystal run bench/cat-044/bench_power_to_math.cr`

# CAT-044: Use `x * x` instead of `x ** 2`, `Math.sqrt` instead of `** 0.5`

`x ** 2` and `x ** 0.5` use the general power operator which may not inline as well.
`x * x` and `Math.sqrt(x)` are more idiomatic and LLVM can optimize better in theory.

> [!NOTE]
> Benchmarks show ~1x difference — LLVM optimizes both forms to identical machine
> code in most cases. This is primarily a **style/educational rule** for Crystal
> newcomers coming from Ruby where `** 2` / `** 0.5` is common but suboptimal.
> In Crystal the compiler handles both equally well. Confidence: `low`.

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

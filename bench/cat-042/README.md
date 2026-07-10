# CAT-042: Use `Fiber.yield` instead of `sleep(0)`

`sleep(0)` is misleading — it suggests a time delay when the intent is to yield control to other fibers. `Fiber.yield` expresses this directly.

## Before / After

```crystal
sleep(0)

# ↓

Fiber.yield
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== sleep(0) vs Fiber.yield ===
n=10      sleep(0)=2.4e-5   s  Fiber.yield=8.0e-6   s  2.83x faster
n=100     sleep(0)=7.0e-5   s  Fiber.yield=7.0e-5   s  1.0x faster
n=1000    sleep(0)=0.000691 s  Fiber.yield=0.000722 s  0.96x faster
n=10000   sleep(0)=0.007162 s  Fiber.yield=0.00704  s  1.02x faster
n=100000  sleep(0)=0.06914  s  Fiber.yield=0.0688   s  1.0x faster
```

## Run

`crystal run bench/cat-042/bench_sleep_zero_to_yield.cr`

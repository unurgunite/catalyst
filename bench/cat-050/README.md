# CAT-050: Use `spawn` instead of `Fiber.new { ... }.resume`

`Fiber.new(&block).resume` creates and immediately resumes a fiber. `spawn` does the same thing more concisely.

## Before / After

```crystal
Fiber.new { do_work }.resume

# ↓

spawn { do_work }
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== Fiber.new vs spawn (creation only) ===
n=10      Fiber.new=2.4e-5   s  spawn=2.2e-5   s  1.06x faster
n=100     Fiber.new=0.000228 s  spawn=0.000231 s  0.99x faster
n=1000    Fiber.new=0.003768 s  spawn=0.005764 s  0.65x faster
n=10000   Fiber.new=0.059322 s  spawn=0.034867 s  1.7x faster
n=100000  Fiber.new=0.57407  s  spawn=0.584606 s  0.98x faster
```

## Run

`crystal run bench/cat-050/bench_fiber_new_to_spawn.cr`

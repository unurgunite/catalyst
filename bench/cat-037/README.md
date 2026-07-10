# CAT-037: Use block form for logging with interpolation

String interpolation in log method arguments is evaluated even when the log level is not enabled. Block form defers evaluation.

## Before / After

```crystal
logger.debug("hello #{name}")     # → logger.debug { "hello #{name}" }
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      interpolated=1.33e-6s     block=4.2e-7s       3.2x faster
n=100     interpolated=1.129e-5s    block=4.6e-7s       24.66x faster
n=1000    interpolated=5.204e-5s    block=9.2e-7s       56.81x faster
n=10000   interpolated=0.00051833s  block=4.75e-6s      109.12x faster
n=100000  interpolated=0.00442712s  block=4.929e-5s     89.82x faster
```

## Run

`crystal run bench/cat-037/bench_logging_block.cr`

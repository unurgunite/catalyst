# CAT-047: Remove redundant `upcase.downcase` chain

`upcase.downcase` allocates two intermediate strings while canceling itself out semantically.
The final result is identical to the original string — but with unnecessary allocation and processing.

## Before / After

```crystal
str.upcase.downcase  # → str
str.downcase.upcase  # → str
```

## Why this matters

- **Unnecessary allocation**: Each call allocates a new String (up to 2x the original size).
- **GC pressure**: Extra strings need garbage collection.
- **Misleading intent**: Reader wonders why the casing transform is needed when it cancels out.

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      chain=2.83e-6s    single=4.2e-7s    6.79x slower
n=100     chain=1.5e-5s     single=3.8e-7s    40.0x slower
n=1000    chain=0.00013542s single=1.04e-6s   130.08x slower
n=10000   chain=0.00137617s single=9.25e-6s   148.77x slower
n=100000  chain=0.01299212s single=8.929e-5s  145.5x slower
```

## Run

`crystal run bench/cat-047/bench_upcase_downcase_noop.cr`

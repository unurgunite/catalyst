# CAT-043: Reuse `Random.new` instance instead of creating each call

Creating a new `Random` instance per call is expensive. Store in a constant or local variable.

## Before / After

```crystal
def random_id : UInt64
  Random.new.rand(UInt64)
end

# ↓

RANDOM = Random.new
def random_id : UInt64
  RANDOM.rand(UInt64)
end
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== Random.new per call vs reused Random ===
n=10      new_each=2.0e-6   s  reused=0.0      s  3.8x faster
n=100     new_each=8.0e-6   s  reused=0.0      s  18.59x faster
n=1000    new_each=6.7e-5   s  reused=1.0e-6   s  48.79x faster
n=10000   new_each=0.000709 s  reused=1.1e-5   s  66.71x faster
n=100000  new_each=0.00659  s  reused=0.000102 s  64.74x faster
```

## Run

`crystal run bench/cat-043/bench_random_new_reuse.cr`

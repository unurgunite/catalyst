# CAT-045: Raise Exception for expected failure → Union(T, Nil)

Raising and rescuing exceptions is expensive: each miss allocates an
exception object and unwinds the stack. When failure is *expected* (cache
miss, lookup miss, validation), returning `nil` from a union return type
(`String?`) keeps the happy path allocation-free.

## Before / After

```crystal
def fetch(key : String) : String
  raise ArgumentError.new("missing") if key.empty?  # → return nil + `: String?`
  "value:#{key}"
end
```

## Results (macOS ARM, Crystal 1.21.0)

```
miss=0.0   raise/rescue=0.006528 s  union=0.005643 s  1.16x faster
miss=0.01  raise/rescue=0.014859 s  union=0.005908 s  2.51x faster
miss=0.1   raise/rescue=0.088554 s  union=0.005903 s  15.0x faster
miss=0.5   raise/rescue=0.452896 s  union=0.003795 s  119.35x faster
```

Exceptions are fine for truly exceptional paths (miss ≈ 0). Past ~1% miss
rate the union return wins by an order of magnitude or more.

## Run

`crystal run bench/cat-045/bench_exception_to_union.cr`

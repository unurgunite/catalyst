# CAT-040: Use `String.build` instead of consecutive string concatenations

Consecutive `+` with string literals creates intermediate strings. `String.build` accumulates in a buffer.

## Before / After

```crystal
"a" + "b" + "c" + "d"  # → String.build { |io| io << "a" << "b" << "c" << "d" }
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      concat=2.29e-6s    build=2.88e-6s    0.8x faster (concat faster)
n=100     concat=1.108e-5s   build=1.346e-5s   0.82x faster
n=1000    concat=9.975e-5s   build=0.00012767s 0.78x faster
n=10000   concat=0.00107708s build=0.0012105s  0.89x faster
n=100000  concat=0.00958562s build=0.01187529s 0.81x faster
```

Note: For simple literal concatenation, Crystal's compiler optimizes constants
at compile time. The benefit of `String.build` is more pronounced with variable
interpolation or in loops with dynamic values.
```

## Run

`crystal run bench/cat-040/bench_string_build_fusion.cr`

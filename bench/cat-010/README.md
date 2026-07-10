# CAT-010: Use `String.build` instead of `String#+` in loops

`String#+` creates a new `String` on every call. In a loop, this means O(n²) allocations as each iteration copies the entire accumulated string. `String.build` writes into a reusable buffer and produces the final string once.

## Before / After

```crystal
str = ""
items.each { |item| str += item.to_s }  # → String.build { |io| items.each { |item| io << item.to_s } }
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      concat=2e-06s    build=2e-06s    1.07x  faster
n=100     concat=1.5e-05s  build=1e-05s    1.54x  faster
n=1000    concat=0.000315s build=8.5e-05s  3.69x  faster
n=10000   concat=0.013597s build=0.000953s 14.26x faster
n=100000  concat=1.065486s build=0.009781s 108.93x faster
```

## Run

`crystal run bench/cat-010/bench_string_plus_to_string_build.cr`

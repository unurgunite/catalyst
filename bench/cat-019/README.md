# CAT-019: Hoist `Regex.new` out of loop to a constant

`Regex.new` compiles a regex pattern each time it is called. Hoisting to a constant compiles once and reuses the regex.

## Before / After

```crystal
[1, 2, 3].each { Regex.new("pattern") }  # → RE = Regex.new("pattern"); [1, 2, 3].each { RE }
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      inside=8.762e-5s   constant=3.3e-7s    263x faster
n=100     inside=0.000223s   constant=3.8e-7s    594x faster
n=1000    inside=0.002204s   constant=1.25e-6s   1763x faster
n=10000   inside=0.022780s   constant=8.21e-6s   2775x faster
n=100000  inside=0.229121s   constant=9.096e-5s  2519x faster
```

## Run

`crystal run bench/cat-019/bench_regex_new_to_constant.cr`

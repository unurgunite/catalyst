# CAT-039: Use class constant for `Regex.new` inside method

`Regex.new` compiles a regex pattern each call. Hoisting to a constant compiles once.

## Before / After

```crystal
def foo
  Regex.new("pattern")  # → RE = Regex.new("pattern"); def foo; RE; end
end
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      inside=7.392e-5s   constant=4.2e-7s     177.69x faster
n=100     inside=0.00026012s  constant=4.2e-7s     623.8x faster
n=1000    inside=0.00211642s  constant=1.12e-6s    1881.26x faster
n=10000   inside=0.02365117s  constant=8.17e-6s    2895.94x faster
n=100000  inside=0.23271738s  constant=8.842e-5s   2632.04x faster
```

## Run

`crystal run bench/cat-039/bench_regex_new_in_method.cr`

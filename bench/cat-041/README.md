# CAT-041: Hoist `URI.parse`/`Time.parse` out of loop to constant

Parsing inside a loop repeats work. Hoisting to a constant parses once.

## Before / After

```crystal
items.each { URI.parse(url) }  # → URI parsed = URI.parse(url); items.each { parsed }
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      inside=3.054e-5s   constant=4.6e-7s     66.54x faster
n=100     inside=7.238e-5s   constant=3.8e-7s     193.0x faster
n=1000    inside=0.00073258s  constant=1.21e-6s    605.94x faster
n=10000   inside=0.00749754s  constant=8.12e-6s    922.77x faster
n=100000  inside=0.07794754s  constant=8.742e-5s   891.67x faster
```

## Run

`crystal run bench/cat-041/bench_parse_to_constant.cr`

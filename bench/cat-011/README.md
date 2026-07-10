# CAT-011: Combine multiple `gsub` calls into a single pass

Chained `.gsub` calls iterate the string multiple times. A single `.gsub` with a hash argument does all replacements in
one pass.

## Before / After

```crystal
str.gsub("a", "b").gsub("c", "d")                    # → str.gsub({"a" => "b", "c" => "d"})
str.gsub("a", "1").gsub("e", "2").gsub("i", "3")     # → str.gsub({"a" => "1", "e" => "2", "i" => "3"})
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      chained=7e-05s     single=0.000103s  0.68x faster
n=100     chained=0.000528s  single=0.000189s  2.80x faster
n=1000    chained=0.005682s  single=0.001991s  2.85x faster
n=10000   chained=0.055898s  single=0.019439s  2.88x faster
```

> [!NOTE]
> Combined regex + hash is ~2.8x faster for moderate-to-large strings (n≥100). At very small sizes (n=10), the combined
> regex overhead slightly outweighs the benefit.

## Run

`crystal run bench/cat-011/bench_multi_pass_gsub.cr`

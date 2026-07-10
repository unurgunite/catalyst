# CAT-033: Single pass instead of select{}.map{}

Crystal lacks `filter_map` (Ruby 2.7+). `compact_map` is `map{}.compact` (not `select{}.map{}`). Manual single-pass via `each` avoids intermediate array allocation.

## Before / After

```crystal
items.select { |x| x.even? }.map { |x| x * 2 }

# ↓

result = [] of Int32
items.each { |x| result << x * 2 if x.even? }
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== select{}.map{} vs single pass (each + manual) ===
n=10      select.map=0.0      s  single_pass=0.0      s  1.2x faster
n=100     select.map=1.0e-6   s  single_pass=1.0e-6   s  1.21x faster
n=1000    select.map=3.0e-6   s  single_pass=3.0e-6   s  1.04x faster
n=10000   select.map=4.8e-5   s  single_pass=4.8e-5   s  0.99x faster
n=100000  select.map=0.000401 s  single_pass=0.000221 s  1.82x faster
```

## Run

`crystal run bench/cat-033/bench_select_map_to_filter_map.cr`

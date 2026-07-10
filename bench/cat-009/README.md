# CAT-009: Use counter hash instead of `group_by{}.map{}.size`

`group_by` builds a hash where each value is an array, then you map to get the size. This allocates many intermediate
arrays. A counter hash with `Hash.new(0)` counts in a single pass.

## Before / After

```crystal
counts = words.group_by { |w| w }.map { |k, v| {k, v.size} }.to_h

# ↓

counts = Hash(String, Int32).new(0)
words.each { |w| counts[w] += 1 }
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== group_by{}.map{}.size vs counter hash ===
n=10      group_by+map+to_h=1.3e-5   s  counter_hash=2.0e-6   s  5.47x faster
n=100     group_by+map+to_h=2.6e-5   s  counter_hash=3.1e-5   s  0.83x faster
n=1000    group_by+map+to_h=0.00018  s  counter_hash=0.000249 s  0.72x faster
n=10000   group_by+map+to_h=0.001847 s  counter_hash=0.002532 s  0.73x faster
n=100000  group_by+map+to_h=0.018361 s  counter_hash=0.024196 s  0.76x faster
```

> [!NOTE]
> Counter hash is faster only at n=10. At larger n, `group_by` is ~1.3x faster because Crystal's `group_by` uses
> internal optimizations. The `group_by` overhead of allocation is less than the hash lookup overhead in the counter loop
> for large datasets. Consider this rule's value context-dependent.

## Run

`crystal run bench/cat-009/bench_group_by_to_counter.cr`

# CAT-009: Use counter hash instead of `group_by{}.map{}.size`

`group_by` builds a hash where each value is an array, then you map to get the size. This allocates many intermediate arrays. A counter hash with `Hash.new(0)` counts in a single pass.

## Before / After

```crystal
counts = words.group_by { |w| w }.map { |k, v| {k, v.size} }.to_h

# ↓

counts = Hash(String, Int32).new(0)
words.each { |w| counts[w] += 1 }
```

## Run

`crystal run bench/cat-009/bench_group_by_to_counter.cr`

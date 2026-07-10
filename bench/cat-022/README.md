# CAT-022: Use `sample` instead of `shuffle.first`

`shuffle.first` shuffles the entire array O(n) then takes the first element, allocating a new array. `sample` picks a random element in O(1) with zero allocation.

## Before / After

```crystal
deck.shuffle.first

# ↓

deck.sample
```

## Run

`crystal run bench/cat-022/bench_shuffle_first_to_sample.cr`

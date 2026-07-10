# CAT-022: Use `sample` instead of `shuffle.first`

`shuffle.first` shuffles the entire array O(n) then takes the first element, allocating a new array. `sample` picks a
random element in O(1) with zero allocation.

## Before / After

```crystal
deck.shuffle.first

# ↓

deck.sample
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== shuffle.first vs sample ===
n=10      shuffle.first=1.2e-5   s  sample=0.0      s  32.56x faster
n=100     shuffle.first=4.0e-6   s  sample=0.0      s  10.0x faster
n=1000    shuffle.first=3.0e-5   s  sample=0.0      s  88.84x faster
n=10000   shuffle.first=0.000295 s  sample=0.0      s  885.76x faster
n=100000  shuffle.first=0.002832 s  sample=0.0      s  6792.07x faster

=== shuffle.first(n) vs sample(n) ===
n=10      shuffle.first(5)=1.0e-6   s  sample(5)=1.0e-6   s  1.08x faster
n=100     shuffle.first(10)=3.0e-6   s  sample(10)=3.0e-6   s  1.13x faster
n=1000    shuffle.first(100)=2.8e-5   s  sample(100)=2.6e-5   s  1.07x faster
n=10000   shuffle.first(1000)=0.000295 s  sample(1000)=0.000247 s  1.19x faster
n=100000  shuffle.first(10000)=0.00295  s  sample(10000)=0.002556 s  1.15x faster
```

## Run

`crystal run bench/cat-022/bench_shuffle_first_to_sample.cr`

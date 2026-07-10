# CAT-035: Use `each_char` instead of `split("")`

`String#split("")` allocates an `Array(Char)`. `String#each_char` iterates without allocation.

## Before / After

```crystal
str.split("")           # → str.each_char
str.split("").each { }  # → str.each_char { }
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      split("")=3.0e-6   s  each_char=3.0e-6   s  0.97x faster
n=100     split("")=0.000161 s  each_char=4.7e-5   s  3.4x faster
n=1000    split("")=0.006684 s  each_char=0.004069 s  1.64x faster
n=10000   split("")=1.246578 s  each_char=0.499156 s  2.5x faster
n=100000  split("")=70.328609s  each_char=45.729214s  1.54x faster
```

## Run

`crystal run bench/cat-035/bench_split_empty_to_each_char.cr`

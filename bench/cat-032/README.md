# CAT-032: Use `split` with limit instead of `split.first` or `split[0]`

`String#split` without limit allocates a full array. With limit `2`, it stops after the first split.

## Before / After

```crystal
str.split(",")[0]    # → str.split(",", 2)[0]
str.split(":").first # → str.split(":", 2).first
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      split(x)[0]=4.0e-6   s  split(x,2)[0]=1.0e-6   s  4.85x faster
n=100     split(x)[0]=0.000167 s  split(x,2)[0]=3.0e-6   s  48.41x faster
n=1000    split(x)[0]=0.00737  s  split(x,2)[0]=0.000157 s  46.93x faster
n=10000   split(x)[0]=0.750561 s  split(x,2)[0]=0.005788 s  129.67x faster
n=100000  split(x)[0]=73.797524s  split(x,2)[0]=0.305607 s  241.48x faster
```

## Run

`crystal run bench/cat-032/bench_split_first_to_split_limit.cr`

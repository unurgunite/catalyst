# CAT-032: Use `split` with limit instead of `split.first` or `split[0]`

`String#split` without limit allocates a full array. With limit `2`, it stops after the first split.

## Before / After

```crystal
str.split(",")[0]    # → str.split(",", 2)[0]
str.split(":").first # → str.split(":", 2).first
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      TBD
n=100     TBD
n=1000    TBD
n=10000   TBD
n=100000  TBD
```

## Run

`crystal run bench/cat-032/bench_split_first_to_split_limit.cr`

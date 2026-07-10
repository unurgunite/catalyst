# CAT-035: Use `each_char` instead of `split("")`

`String#split("")` allocates an `Array(Char)`. `String#each_char` iterates without allocation.

## Before / After

```crystal
str.split("")           # → str.each_char
str.split("").each { }  # → str.each_char { }
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

`crystal run bench/cat-035/bench_split_empty_to_each_char.cr`

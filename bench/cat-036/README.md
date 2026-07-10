# CAT-036: Use `each_char` instead of `chars.each`

`String#chars` allocates an intermediate `Array(Char)`. `String#each_char` iterates directly.

## Before / After

```crystal
str.chars.each { |c| puts c }  # → str.each_char { |c| puts c }
str.chars.each                  # → str.each_char
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

`crystal run bench/cat-036/bench_chars_each_to_each_char.cr`

# CAT-036: Use `each_char` instead of `chars.each`

`String#chars` allocates an intermediate `Array(Char)`. `String#each_char` iterates directly.

## Before / After

```crystal
str.chars.each { |c| puts c }  # → str.each_char { |c| puts c }
str.chars.each                  # → str.each_char
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      chars.each=2.0e-6   s  each_char=1.0e-6   s  2.24x faster
n=100     chars.each=3.1e-5   s  each_char=1.0e-6   s  52.6x faster
n=1000    chars.each=0.002541 s  each_char=2.0e-6   s  1605.07x faster
n=10000   chars.each=0.226516 s  each_char=9.0e-6   s  24161.73x faster
```

## Run

`crystal run bench/cat-036/bench_chars_each_to_each_char.cr`

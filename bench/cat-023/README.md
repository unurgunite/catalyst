# CAT-023: Use `Char` literal instead of single-character `String` for `includes?`/`count`/`delete` etc.

String methods accepting a single character as a String allocate. Passing a `Char` literal bypasses string creation.

## Before / After

```crystal
str.includes?("x")
str.count("x")

# ↓

str.includes?('x')
str.count('x')
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== str.includes?("x") vs str.includes?('x') ===
n=10      includes?("_")=2.0e-6   s  includes?('_')=1.0e-6   s  1.2x faster
n=100     includes?("_")=7.0e-6   s  includes?('_')=7.0e-6   s  1.05x faster
n=1000    includes?("_")=7.1e-5   s  includes?('_')=6.8e-5   s  1.05x faster
n=10000   includes?("_")=0.000682 s  includes?('_')=0.000699 s  0.98x faster
n=100000  includes?("_")=0.006922 s  includes?('_')=0.007374 s  0.94x faster

=== str.count("x") vs str.count('x') ===
n=10      count("_")=5.0e-6   s  count('_')=1.0e-6   s  3.94x faster
n=100     count("_")=3.2e-5   s  count('_')=9.0e-6   s  3.66x faster
n=1000    count("_")=0.00034  s  count('_')=8.6e-5   s  3.98x faster
n=10000   count("_")=0.003388 s  count('_')=0.000907 s  3.74x faster
n=100000  count("_")=0.036615 s  count('_')=0.00856  s  4.28x faster
```

> [!NOTE]
> `includes?` shows negligible difference. `count` with char is ~4x faster.

## Run

`crystal run bench/cat-023/bench_includes_string_to_char.cr`

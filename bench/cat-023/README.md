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

## Run

`crystal run bench/cat-023/bench_includes_string_to_char.cr`

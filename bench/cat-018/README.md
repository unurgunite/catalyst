# CAT-018: Use `matches?` instead of `match` or `=~` for boolean context

`String#match` returns a `MatchData | Nil` object which is wasteful when only a boolean check is needed. `String#matches?` returns `Bool` directly without allocating a `MatchData` object.

## Before / After

```crystal
str.match(/pattern/)   # → str.matches?(/pattern/)
str =~ /pattern/       # → str.matches?(/pattern/)
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      match=5.0e-6   s  matches?=1.0e-6   s  4.48x faster
n=100     match=9.0e-6   s  matches?=8.0e-6   s  1.17x faster
n=1000    match=8.9e-5   s  matches?=7.5e-5   s  1.19x faster
n=10000   match=0.000884 s  matches?=0.000789 s  1.12x faster
n=100000  match=0.008421 s  matches?=0.007524 s  1.12x faster
```

## Run

`crystal run bench/cat-018/bench_match_to_matches.cr`

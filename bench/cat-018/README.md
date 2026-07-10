# CAT-018: Use `matches?` instead of `match` or `=~` for boolean context

`String#match` returns a `MatchData | Nil` object which is wasteful when only a boolean check is needed. `String#matches?` returns `Bool` directly without allocating a `MatchData` object.

## Before / After

```crystal
str.match(/pattern/)   # → str.matches?(/pattern/)
str =~ /pattern/       # → str.matches?(/pattern/)
```

## Results (macOS ARM, Crystal 1.20.3)

```

```

## Run

`crystal run bench/cat-018/bench_match_to_matches.cr`

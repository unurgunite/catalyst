# CAT-008: Use `find` instead of `select.first` / `select.first?`

`select{}.first` iterates the entire collection and builds a new array, then takes the first element. `find!` stops at the first match, short-circuiting.

## Before / After

```crystal
first_admin = users.select { |u| u.admin }.first

# ↓

first_admin = users.find! { |u| u.admin }
```

## Run

`crystal run bench/cat-008/bench_select_first.cr`

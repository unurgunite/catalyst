# CAT-008: Use `find` instead of `select.first` / `select.first?`

`select{}.first` iterates the entire collection and builds a new array, then takes the first element. `find!` stops at the first match, short-circuiting.

## Before / After

```crystal
first_admin = users.select { |u| u.admin }.first

# ↓

first_admin = users.find! { |u| u.admin }
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== select{}.first vs find!{} ===
n=10      select{}.first=1.0e-6   s  find!{}          =1.0e-6   s  1.69x faster
n=100     select{}.first=1.0e-6   s  find!{}          =1.0e-6   s  2.2x faster
n=1000    select{}.first=7.0e-6   s  find!{}          =2.0e-6   s  2.91x faster
n=10000   select{}.first=6.2e-5   s  find!{}          =2.0e-5   s  3.09x faster
n=100000  select{}.first=0.000581 s  find!{}          =0.000176 s  3.3x faster

=== select(&:cond).first? vs find{} ===
n=10      select{}.first?=1.0e-6   s  find{}          =0.0      s  1.36x faster
n=100     select{}.first?=1.0e-6   s  find{}          =1.0e-6   s  2.36x faster
n=1000    select{}.first?=7.0e-6   s  find{}          =2.0e-6   s  3.0x faster
n=10000   select{}.first?=5.5e-5   s  find{}          =1.7e-5   s  3.19x faster
n=100000  select{}.first?=0.000606 s  find{}          =0.00018  s  3.36x faster
```

## Run

`crystal run bench/cat-008/bench_select_first.cr`

# CAT-003: Use `partition` instead of `select` + `reject`

Calling `select{...}` and `reject{...}` separately iterates the collection twice. `partition{...}` does both in a single pass, allocating one array for matched and one for unmatched elements.

## Before / After

```crystal
selected = arr.select { |x| x > 5 }
rejected = arr.reject { |x| x > 5 }

# ↓

selected, rejected = arr.partition { |x| x > 5 }
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      select+reject=1e-06s    partition=1e-06s    0.93x faster
n=100     select+reject=1e-06s    partition=1e-06s    1.35x faster
n=1000    select+reject=3e-06s    partition=3e-06s    0.89x faster
n=10000   select+reject=6.9e-05s  partition=5.3e-05s  1.30x faster
n=100000  select+reject=0.000766s partition=0.000731s 1.05x faster
```

## Run

`crystal run bench/cat-003/bench_select_reject_to_partition.cr`

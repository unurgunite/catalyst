# CAT-018: Use `compare(case_insensitive: true)` instead of `downcase` + `==`

`String#downcase` allocates a new downcased string. `String#compare(case_insensitive: true)` compares case-insensitively without allocation.

## Before / After

```crystal
str.downcase == other.downcase  # → str.compare(other, case_insensitive: true) == 0
str.downcase == "foo"           # → str.compare("foo", case_insensitive: true) == 0
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10     (len=120   )  downcase+== 2.0e-6s   compare(ci)=2.0e-6s    1.07x faster
n=100    (len=1200  )  downcase+== 1.2e-5s   compare(ci)=1.1e-5s    1.03x faster
n=1000   (len=12000 )  downcase+== 9.3e-5s   compare(ci)=0.000106s  0.87x faster
n=10000  (len=120000)  downcase+== 0.000948s compare(ci)=0.001125s  0.84x faster
n=100000 (len=1200000) downcase+== 0.00925s  compare(ci)=0.010268s  0.90x faster
```

Note: `compare(case_insensitive: true)` avoids string allocation but per-character folding
is slower than downcase+memcmp for medium-to-large strings. Benefit appears in memory-constrained
or GC-heavy scenarios (e.g., loop with many comparisons).

## Run

`crystal run bench/cat-018/bench_downcase_compare.cr`

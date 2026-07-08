# CAT-017: Use `Time.utc` instead of `Time.local`

`Time.local` creates a time in the local timezone (involves timezone lookup/conversion). `Time.utc` creates in UTC without conversion overhead.

## Before / After

```crystal
Time.local(2024, 1, 1)  # → Time.utc(2024, 1, 1)
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== Time.local vs Time.utc ===

Creating Time 1000 times:

  Time.local(2024,1,1,12,30,45) x 1000 = 0.000293s
  Time.utc(2024,1,1,12,30,45) x 1000    = 6.5e-5s
  4.54x faster

Creating Time with date components:

  Time.local(2024, 1, 1) x 1000 = 0.000134s
  Time.utc(2024, 1, 1) x 1000    = 6.4e-5s
  2.08x faster
```

## Run

`crystal run bench/cat-017/bench_time_local_to_utc.cr`

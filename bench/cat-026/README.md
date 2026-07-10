# CAT-026: Dir.open resource leak

`Dir.open(path)` without block requires manual `close`. Block form auto-closes.

## Before / After

```crystal
d = Dir.open(".")
d.entries
d.close
```

```crystal
Dir.open(".") { |d| d.entries }
```

## Results (TBD — run locally)

```
n=10      no-block=?s  block=?s  ?x faster
n=100     no-block=?s  block=?s  ?x
n=1000    no-block=?s  block=?s  ?x
n=10000   no-block=?s  block=?s  ?x
n=100000  no-block=?s  block=?s  ?x
```

## Run

`crystal run bench/cat-026/bench_dir_open_leak.cr`

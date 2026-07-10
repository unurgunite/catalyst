# CAT-025: File.open resource leak

`File.open(path)` without block requires manual `close`. Block form auto-closes.

## Before / After

```crystal
f = File.open("file.txt")
f.gets
f.close
```

```crystal
File.open("file.txt") { |f| f.gets }
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

`crystal run bench/cat-025/bench_file_open_leak.cr`

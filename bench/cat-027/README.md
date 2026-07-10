# CAT-027: Tempfile resource leak

`Tempfile.new(name)` without block requires manual `close`. Block form auto-closes.

## Before / After

```crystal
f = Tempfile.new("data")
f.puts "hello"
f.close
```

```crystal
Tempfile.new("data") { |f| f.puts "hello" }
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

`crystal run bench/cat-027/bench_tempfile_leak.cr`

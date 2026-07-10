# CAT-029: DB.open resource leak

`DB.open(url)` without block requires manual `close`. Block form auto-closes.

## Before / After

```crystal
db = DB.open("postgres://localhost/mydb")
db.exec("SELECT 1")
db.close
```

```crystal
DB.open("postgres://localhost/mydb") { |db| db.exec("SELECT 1") }
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

`crystal run bench/cat-029/bench_db_open_leak.cr`

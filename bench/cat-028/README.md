# CAT-028: HTTP::Client resource leak

`HTTP::Client.new(url)` without block requires manual `close`. Block form auto-closes.

## Before / After

```crystal
c = HTTP::Client.new("https://example.com")
c.get("/")
c.close
```

```crystal
HTTP::Client.new("https://example.com") { |c| c.get("/") }
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

`crystal run bench/cat-028/bench_http_client_leak.cr`

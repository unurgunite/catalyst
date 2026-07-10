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

## Results (macOS ARM, Crystal 1.20.3)

```
=== HTTP::Client.new without block vs with block ===

Block form ensures close even on exceptions (safety, not speed).

n=10      manual=1.1e-5   s  block=1.0e-6   s  7.96x faster
n=100     manual=8.0e-6   s  block=1.5e-5   s  0.5x faster
n=1000    manual=0.000136 s  block=0.000116 s  1.18x faster
n=10000   manual=0.000724 s  block=0.000755 s  0.96x faster
n=100000  manual=0.007501 s  block=0.007466 s  1.0x faster
```

## Run

`crystal run bench/cat-028/bench_http_client_leak.cr`

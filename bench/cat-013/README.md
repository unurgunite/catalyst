# CAT-013: TCPSocket resource leak

`TCPSocket.new` without block form requires manual `close` in `ensure`.
Block form (`TCPSocket.open`) auto-closes the socket when block exits, preventing resource leaks.

## Before / After

```crystal
s = TCPSocket.new("example.com", 80)
s.gets
s.close
```

```crystal
TCPSocket.open("example.com", 80) { |s| s.gets }
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      manual=1.0e-6s    block=0.0s        1.36x faster
n=100     manual=2.0e-6s    block=1.0e-6s     1.52x faster
n=1000    manual=1.5e-5s    block=1.1e-5s     1.42x faster
n=10000   manual=0.000145s  block=8.3e-5s     1.75x faster
n=100000  manual=0.001004s  block=0.00102s    0.98x faster
```

Block form is slightly faster at lower iteration counts (no manual close branch). At 100K iterations both patterns converge (identical overhead).

## Run

`crystal run bench/cat-013/bench_tcp_socket_leak.cr`

# CAT-020: Use `String.build` instead of `IO::Memory` + `.to_s`

`IO::Memory` adds overhead for buffering. `String.build` builds strings directly and is more efficient.

## Before / After

```crystal
io = IO::Memory.new
io << "hello"
io << " world"
io.to_s
```

```crystal
String.build { |sb| sb << "hello" << " world" }
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      IO::Memory=2.0e-6s    String.build=2.0e-6s    0.80x faster
n=100     IO::Memory=6.0e-6s    String.build=3.0e-6s    1.92x faster
n=1000    IO::Memory=2.7e-5s    String.build=2.6e-5s    1.05x faster
n=10000   IO::Memory=0.000234s  String.build=0.000214s  1.09x faster
n=100000  IO::Memory=0.002364s  String.build=0.001918s  1.23x faster
```

## Run

`crystal run bench/cat-020/bench_io_memory.cr`

# CAT-014: Use streaming instead of `File.read` / `File.read_lines`

`File.read` loads the entire file into memory as a single `String`.
`File.read_lines` allocates an `Array(String)` with all lines.
For large files, use `File.open` with `each_line` to stream content line-by-line.

## Before / After

```crystal
File.read("large.txt")                          # → File.open("large.txt") { |f| f.each_line { ... } }
File.read_lines("large.txt").each { |line| ... } # → File.open("large.txt") { |f| f.each_line { |line| ... } }
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      File.read=4.1e-5s     File.each_line=3.5e-5s     1.17x faster
n=100     File.read=2.7e-5s     File.each_line=2.2e-5s     1.26x faster
n=1000    File.read=9.2e-5s     File.each_line=1.95e-4s    0.47x faster
n=10000   File.read=8.25e-4s    File.each_line=1.131e-3s   0.73x faster
n=100000  File.read=7.491e-3s   File.each_line=1.0955e-2s  0.68x faster

n=10      File.read_lines=2.3e-5s  File.each_line=1.2e-5s  1.88x faster
n=100     File.read_lines=2.8e-5s  File.each_line=2.2e-5s  1.24x faster
n=1000    File.read_lines=1.32e-4s File.each_line=1.21e-4s 1.09x faster
n=10000   File.read_lines=1.203e-3s File.each_line=1.116e-3s 1.08x faster
n=100000  File.read_lines=1.128e-2s File.each_line=1.1241e-2s 1.00x faster
```

> [!NOTE]
> The main benefit of streaming is **memory efficiency**, not raw speed.
> `File.read` loads the entire file into memory (O(n) memory), while `File.open` + `each_line`
> processes line-by-line (O(1) memory). For very large files, streaming prevents OOM.

## Run

`crystal run bench/cat-014/bench_file_read_to_streaming.cr`

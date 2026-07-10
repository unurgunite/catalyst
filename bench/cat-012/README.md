# CAT-012: Use `JSON::Serializable` instead of `JSON.parse` with manual access

`JSON.parse(str).as_h` and `JSON.parse(str).as_a` allocate intermediate `JSON::Any` values and require manual key access with type casts. `JSON::Serializable` parses directly into typed structs at compile time.

## Before / After

```crystal
h = JSON.parse(raw).as_h              # → point = Point.from_json(raw)
h["x"].as_i64                          # → point.x
```

## Results (macOS ARM, Crystal 1.20.3)

```
n=10      parse+.as_h=7.2e-5s     from_json=2.5e-5s     2.82x faster
n=100     parse+.as_h=0.000139s   from_json=0.000137s   1.02x faster
n=1000    parse+.as_h=0.001516s   from_json=0.001424s   1.06x faster
n=10000   parse+.as_h=0.015382s   from_json=0.014634s   1.05x faster
n=100000  parse+.as_h=0.163131s   from_json=0.154802s   1.05x faster
```

## Run

`crystal run bench/cat-012/bench_json_parse_to_serializable.cr`

# CAT-016: Large union types

Large union types (4+ types) in method return signatures force the compiler to generate larger dispatch tables and can indicate over-general APIs. Consider refactoring with a sealed class/struct hierarchy or protocol instead.

> **Caveat**: This rule targets **compile-time performance** (compiler speed, binary size), not runtime. The benchmark measures AST parsing overhead, not execution speed. Marginal rule — useful for large codebases but low priority for small projects.

## Before / After

```crystal
# Before: large union
def handle(value : Int32 | String | Nil | Bool) : Int32 | String | Nil | Bool
  value
end

# After: specific types or hierarchy
def handle(value : Int32 | String) : Int32 | String
  value
end
```

## Results (macOS ARM, Crystal 1.20.3)

```
=== LargeUnionTypes rule benchmark ===

def with 4-type union 767.56k (  1.30µs) (± 2.23%)   4.2kB/op   1.75× slower
 def with single type   1.35M (742.56ns) (± 1.72%)  2.79kB/op        fastest
```

## Run

`crystal run bench/cat-016/bench_large_union_types.cr`

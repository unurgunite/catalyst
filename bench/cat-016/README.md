# CAT-016: Large union types

Large union types (4+ types) in method return signatures force the compiler to generate larger dispatch tables and can indicate over-general APIs. Consider refactoring with a sealed class/struct hierarchy or protocol instead.

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

## Run

`crystal run bench/cat-016/bench_large_union_types.cr`

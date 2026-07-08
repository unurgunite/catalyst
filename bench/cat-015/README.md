# CAT-015: Use Struct instead of Class for small data objects

Small classes that are just data containers (properties only, few instance variables) should be `struct` instead of `class`. Structs are stack-allocated value types — faster allocation, less GC pressure.

## Before / After

```crystal
class Point
  property x, y
  def initialize(@x : Int32, @y : Int32)
  end
end

# → convert to struct

struct Point
  property x, y
  def initialize(@x : Int32, @y : Int32)
  end
end
```

## Thresholds

The rule fires when:
- No parent class (or parent is implicit `Reference`)
- ≤4 instance variables
- Only accessor macros (`property`/`getter`/`setter`) and `def initialize`
- No custom methods with logic

## Run

`crystal run bench/cat-015/bench_struct_vs_class.cr`

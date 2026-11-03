#!/bin/sh
# Runs as this shard's postinstall hook, from the installed copy inside a
# consumer's lib/ directory.
#
# Shards installs a dependency with a full git mirror clone, so everything
# committed here lands in that consumer's project: bench/, spec/, .github/,
# the pre-commit and docs tooling. Compiling the library needs src/ and
# scripts/generate_rules_require.cr (it is executed at compile time by
# `run(...)` in src/catalyst.cr) and nothing else.
#
# Two safety rules:
#   - never delete when this runs in the source repo itself;
#   - skip under CI, where a full checkout is the point.
set -eu

# The hook runs from the shard's root, but scripts/ may be invoked from
# anywhere, so anchor on the script's own location.
here=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

case "$here" in
  */lib/*) ;;
  *)
    echo "trim_shard: not an installed shard ($here), leaving it alone"
    exit 0
    ;;
esac

[ -n "${CI:-}" ] && exit 0

for path in bench spec .github hello_enterprise battle .idea docs; do
  [ -e "$here/$path" ] && rm -rf "$here/$path"
done

# Keep in sync with .gitignore: these are build outputs and local state.
rm -rf "$here/lib" "$here/bin/ameba" "$here/bin/ameba.exe"
rm -f "$here"/rules_*.txt "$here"/build_categorization.py

echo "trim_shard: trimmed $(basename "$here") to src/, scripts/ and bin/"

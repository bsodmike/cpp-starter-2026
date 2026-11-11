#!/usr/bin/env bash
# Runs clang-tidy over the files given, against the first configured build tree
# that has a compile_commands.json. Skips rather than fails when the tree is not
# configured yet, so a fresh clone can still commit.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

if [ "$#" -eq 0 ]; then
  exit 0
fi

build_dir=""
for candidate in build/dev build/dev-clang build/ci-linux-clang build/ci-linux-gcc; do
  if [ -f "$candidate/compile_commands.json" ]; then
    build_dir="$candidate"
    break
  fi
done

if [ -z "$build_dir" ]; then
  echo "pre-commit: no configured build tree found; run 'cmake --preset dev' to enable clang-tidy here." >&2
  exit 0
fi

if ! command -v clang-tidy >/dev/null 2>&1; then
  echo "pre-commit: clang-tidy not on PATH; skipping." >&2
  exit 0
fi

# tests/consumer is a standalone project and is absent from this build tree.
files=()
for file in "$@"; do
  case "$file" in
    tests/consumer/*) continue ;;
  esac
  files+=("$file")
done

if [ ${#files[@]} -eq 0 ]; then
  exit 0
fi

clang-tidy -p "$build_dir" --warnings-as-errors='*' "${files[@]}"

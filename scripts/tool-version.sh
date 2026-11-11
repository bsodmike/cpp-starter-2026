#!/usr/bin/env bash
# Prints the pinned version of one tool from .tool-versions.
#   usage: scripts/tool-version.sh cmake
set -euo pipefail

tool=${1:?usage: tool-version.sh <tool>}
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

version=$(awk -v tool="$tool" '!/^#/ && $1 == tool { print $2; found = 1 } END { exit !found }' \
  "$root/.tool-versions") || {
  echo "no pinned version for '$tool' in .tool-versions" >&2
  exit 1
}

printf '%s\n' "$version"

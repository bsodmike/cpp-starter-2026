#!/usr/bin/env bash
# Rejects blanket suppressions. Every NOLINT must name the check it silences,
# and MSVC warning pragmas must name a warning number, so review can tell what
# was waived and why.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

sources=(--include='*.cpp' --include='*.hpp' --include='*.h')
dirs=(src app tests benchmarks)
status=0

# Find every NOLINT mention, then drop the ones that name their checks. Done in
# two passes because a single regex for "NOLINT not followed by (check)" is
# easy to get subtly wrong.
blanket_nolint=$(grep -rn "${sources[@]}" -e 'NOLINT' "${dirs[@]}" 2>/dev/null \
  | grep -vE 'NOLINT(NEXTLINE|BEGIN|END)?\([A-Za-z0-9_,.*-]+\)' || true)

if [ -n "$blanket_nolint" ]; then
  echo "Blanket NOLINT found; name the specific check, e.g. NOLINT(bugprone-foo):" >&2
  echo "$blanket_nolint" >&2
  status=1
fi

blanket_pragma=$(grep -rnE "${sources[@]}" \
  -e '#pragma +warning *\( *(disable|default|error) *\)' "${dirs[@]}" 2>/dev/null || true)

if [ -n "$blanket_pragma" ]; then
  echo "Blanket '#pragma warning(...)' found; name the warning number:" >&2
  echo "$blanket_pragma" >&2
  status=1
fi

if [ "$status" -eq 0 ]; then
  echo "No blanket suppressions."
fi

exit "$status"

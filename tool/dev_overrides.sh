#!/usr/bin/env bash
# Points the Flutter package and its examples at the local yalla_pay_sudan_core
# checkout, so both packages can be developed and tested together before (or
# without) publishing core. Writes git-ignored pubspec_overrides.yaml files.
#
# Usage: bash tool/dev_overrides.sh          # create overrides
#        bash tool/dev_overrides.sh --remove # delete them
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"

targets=(
  "packages/yalla_pay_sudan:../yalla_pay_sudan_core"
  "packages/yalla_pay_sudan/example:../../yalla_pay_sudan_core"
)

for entry in "${targets[@]}"; do
  dir="$root/${entry%%:*}"
  rel="${entry#*:}"
  [ -d "$dir" ] || continue
  file="$dir/pubspec_overrides.yaml"
  if [ "${1:-}" = "--remove" ]; then
    rm -f "$file"
    echo "removed ${file#"$root"/}"
  else
    printf 'dependency_overrides:\n  yalla_pay_sudan_core:\n    path: %s\n' "$rel" > "$file"
    echo "wrote ${file#"$root"/}"
  fi
done

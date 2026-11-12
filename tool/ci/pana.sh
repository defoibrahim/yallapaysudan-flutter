#!/usr/bin/env bash
# Runs pana on one package and fails unless it scores 160/160.
#
# Usage: tool/ci/pana.sh <package-dir> [extra pana args...]
#
# One exception, pull requests only: pana verifies the pubspec `repository`
# URL against the repository's *default branch*. A package that does not
# exist on main yet (its first PR) cannot pass that check until it is merged,
# so in that case, and only if that is the sole missing 10 points, the job
# passes with a warning. On main the gate is always strict.
set -euo pipefail
pkg="$1"
shift
report="$(mktemp)"

set +e
dart pub global run pana --exit-code-threshold 0 "$@" "$pkg" | tee "$report"
status=${PIPESTATUS[0]}
set -e

grep -E '^## |^Points:' "$report" | sed "s#^#[$pkg] #" >> "${GITHUB_STEP_SUMMARY:-/dev/null}" || true
[ "$status" -eq 0 ] && exit 0

if [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ] &&
  ! git cat-file -e "origin/main:$pkg/pubspec.yaml" 2>/dev/null &&
  grep -q '^Points: 150/160' "$report" &&
  grep -q 'Repository has no matching `pubspec.yaml`' "$report"; then
  echo "::warning::$pkg is not on main yet, so pana cannot verify its repository URL (-10). Everything else scores; main runs the strict 160/160 gate after merge."
  exit 0
fi
echo "::error::pana scored below 160/160 for $pkg"
exit 1

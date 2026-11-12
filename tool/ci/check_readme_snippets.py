#!/usr/bin/env python3
"""Checks that every ```dart block in a README appears in a Dart file.

The Dart file is analyzed in CI, so this keeps README samples compiling.
Lines are compared with surrounding whitespace removed and blank lines
skipped, so a sample may sit indented inside a function in the Dart file.

Usage: check_readme_snippets.py README.md path/to/snippets.dart
"""
import re
import sys


def norm(lines):
    return [line.strip() for line in lines if line.strip()]


def main():
    readme, dart = sys.argv[1], sys.argv[2]
    blocks = re.findall(r"```dart\n(.*?)```", open(readme, encoding="utf-8").read(), re.S)
    source = norm(open(dart, encoding="utf-8").read().splitlines())
    missing = 0
    for block in blocks:
        want = norm(block.splitlines())
        found = any(source[i:i + len(want)] == want for i in range(len(source) - len(want) + 1))
        if not found:
            missing += 1
            print(f"::error file={readme}::README sample not found verbatim in {dart}:\n{block}")
    print(f"{readme}: {len(blocks) - missing}/{len(blocks)} dart samples are in {dart}")
    sys.exit(1 if missing else 0)


if __name__ == "__main__":
    main()

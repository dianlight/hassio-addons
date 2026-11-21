#!/usr/bin/env python3
"""Deterministic changelog release transitions for hassio-addons.

Maintains the invariant:

  - `## Unreleased` is always the first section and exists even when empty.
  - Versioned headings appear ONLY for released versions.

Transitions:

  promote <version> <date>
      Move the whole `## Unreleased` content under
      `## [<version>] - <date>` and leave a fresh empty `## Unreleased` on top.

      Used when a release is cut (stable or beta): the pending content becomes
      the released content.

  demote <version>
      Move the content of the versioned heading for `<version>` back under
      `## Unreleased` and drop the version heading.

      Used when a version is NOT released (e.g. a release PR was reverted / the
      release never shipped): all content of that version returns to Unreleased.

  strip
      Remove the `## Unreleased` block entirely (release/beta branch content:
      Unreleased was already promoted, S2 = S1 minus U).

Usage:
  changelog_release.py <CHANGELOG> <promote|demote|strip> [args]

Subcommands:
  promote <version> <date>
  demote <version>
  strip
"""

import re
import sys
from pathlib import Path

UNRELEASED_RE = re.compile(r"^##\s+Unreleased\s*$", re.IGNORECASE)

# `## [2026.11.0] - 2026-11-17` or `## 2026.10.2` or `## 2026.10.0-rc19`
VERSIONED_RE = re.compile(
    r"^##\s+(?:\[(?P<bracket>[^]]+)\]\s*-\s*(?P<bracket_date>\d{4}-\d{2}-\d{2})"
    r"|(?P<bare>\S.*))",
    re.IGNORECASE,
)


def version_of(line: str):
    m = VERSIONED_RE.match(line)
    if not m:
        return None
    if m.group("bracket") is not None:
        return m.group("bracket").strip()
    return m.group("bare").strip()


def is_unreleased(line: str) -> bool:
    return bool(UNRELEASED_RE.match(line))


def read_lines(path: Path) -> list:
    return path.read_text(encoding="utf-8").splitlines()


def write_lines(path: Path, lines: list) -> None:
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def find_unreleased(lines: list) -> int:
    for i, line in enumerate(lines):
        if is_unreleased(line):
            return i
    raise ValueError("no '## Unreleased' section found")


def find_versioned(lines: list, start: int) -> int:
    """Index of the first versioned heading at/after `start`, else len(lines)."""
    for i in range(start, len(lines)):
        if not is_unreleased(lines[i]) and version_of(lines[i]) is not None:
            return i
    return len(lines)


def block_between(lines: list, start: int, end: int) -> list:
    """Content lines between heading index `start` and next versioned heading."""
    block: list = []
    for line in lines[start + 1 : end]:
        if is_unreleased(line) or version_of(line) is not None:
            break
        block.append(line)
    while block and not block[0].strip():
        block.pop(0)
    while block and not block[-1].strip():
        block.pop()
    return block


def cmd_promote(path: Path, version: str, date: str) -> None:
    lines = read_lines(path)
    u = find_unreleased(lines)
    j = find_versioned(lines, u + 1)
    if j < len(lines) and version_of(lines[j]) == version:
        raise ValueError(f"version heading '## [{version}] - {date}' already exists")
    content = block_between(lines, u, j)
    new_lines = lines[:u]
    new_lines.append("## Unreleased")
    new_lines.append("")
    new_lines.append(f"## [{version}] - {date}")
    new_lines.append("")
    new_lines.extend(content)
    if j < len(lines):
        new_lines.append("")
        new_lines.extend(lines[j:])
    else:
        new_lines.append("")
    new_lines.append("")
    write_lines(path, new_lines)


def cmd_demote(path: Path, version: str) -> None:
    lines = read_lines(path)
    u = find_unreleased(lines)
    j = find_versioned(lines, u + 1)
    target = None
    for k in range(u + 1, j + 1):
        if version_of(lines[k]) == version:
            target = k
            break
    if target is None:
        raise ValueError(f"no versioned heading for version '{version}' found")
    j2 = find_versioned(lines, target + 1)
    un_block = block_between(lines, u, j)
    ver_block = block_between(lines, target, j2)
    merged = list(un_block)
    if un_block and ver_block:
        merged.append("")
        merged.extend(ver_block)
    elif ver_block:
        merged = list(ver_block)
    new_lines = lines[:u + 1]
    new_lines.append("")
    new_lines.extend(merged)
    if j2 < len(lines):
        new_lines.append("")
        new_lines.extend(lines[j2:])
    else:
        new_lines.append("")
    write_lines(path, new_lines)


def cmd_strip(path: Path) -> None:
    lines = read_lines(path)
    u = find_unreleased(lines)
    j = find_versioned(lines, u + 1)
    new_lines = lines[:u]
    new_lines.extend(lines[j:])
    write_lines(path, new_lines)


def main(argv: list) -> int:
    if len(argv) < 3:
        print(
            "usage: changelog_release.py <CHANGELOG> <promote|demote|strip> [args]",
            file=sys.stderr,
        )
        return 1
    path = Path(argv[1])
    cmd = argv[2]
    if cmd == "promote":
        if len(argv) != 5:
            print("usage: changelog_release.py <CHANGELOG> promote <version> <date>", file=sys.stderr)
            return 1
        cmd_promote(path, argv[3], argv[4])
    elif cmd == "demote":
        if len(argv) != 4:
            print("usage: changelog_release.py <CHANGELOG> demote <version>", file=sys.stderr)
            return 1
        cmd_demote(path, argv[3])
    elif cmd == "strip":
        cmd_strip(path)
    else:
        print(f"unknown subcommand: {cmd}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

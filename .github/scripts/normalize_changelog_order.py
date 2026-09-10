#!/usr/bin/env python3
"""Normalize <addon>/CHANGELOG.md: move ### Thanks / ### Notes sections
to the top of the first versioned (non-Unreleased) release.

- Only ###-level headers inside the first ## release that is not Unreleased
  are reordered. H4 subsections (e.g. inside the SRAT block) are untouched.
- Thanks  = header contains U+1F64F or text is/ends with "thanks".
- Notes   = header contains U+1F6A8 (### 🚨 Notes). "🔄 Migration Notes" is NOT matched.
- Idempotent: exits 0 with "unchanged" when already ordered.
- Styles without Thanks/Notes sections are left untouched.

Usage: normalize_changelog_order.py CHANGELOG.md
The changelog path is required (no default: this shared copy is not tied
to a single add-on directory).
"""
import re
import sys
from pathlib import Path

THANKS_EMOJI = "\U0001F64F"
NOTES_EMOJI = "\U0001F6A8"


def split_sections(block_lines):
    """Split a release block into (preamble, [(header, body_lines), ...])."""
    preamble, sections = [], []
    current = None
    for line in block_lines:
        if line.startswith("### "):
            current = [line]
            sections.append(current)
        elif current is None:
            preamble.append(line)
        else:
            current.append(line)
    return preamble, [(s[0], s[1:]) for s in sections]


def is_thanks(header):
    text = header[4:].strip().lower()
    return THANKS_EMOJI in header or text == "thanks" or text.endswith(" thanks")


def is_notes(header):
    return NOTES_EMOJI in header


def main(path):
    lines = Path(path).read_text().splitlines(keepends=True)
    # Locate first ## release that is not Unreleased.
    first = None
    for i, line in enumerate(lines):
        if line.startswith("## ") and "unreleased" not in line.lower():
            first = i
            break
    if first is None:
        print("no versioned release found, unchanged")
        return 0
    end = len(lines)
    for j in range(first + 1, len(lines)):
        if lines[j].startswith("## "):
            end = j
            break
    preamble, sections = split_sections(lines[first + 1 : end])
    thanks = [(h, b) for h, b in sections if is_thanks(h)]
    notes = [(h, b) for h, b in sections if not is_thanks(h) and is_notes(h)]
    rest = [(h, b) for h, b in sections if not is_thanks(h) and not is_notes(h)]
    ordered = thanks + notes + rest
    if ordered == sections:
        print("section order already correct, unchanged")
        return 0
    out = (
        lines[: first + 1]
        + preamble
        + [ln for h, b in ordered for ln in [h, *b]]
        + lines[end:]
    )
    Path(path).write_text("".join(out))
    print("moved Thanks/Notes to top of first versioned release")
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: normalize_changelog_order.py CHANGELOG.md", file=sys.stderr)
        sys.exit(1)
    sys.exit(main(sys.argv[1]))

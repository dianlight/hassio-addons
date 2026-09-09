#!/usr/bin/env python3
"""Shim: the implementation moved to .github/scripts/ as part of the generic
opencode-changelog refactor. This wrapper preserves the old path for existing
references (workflow history, docs, local tooling) and stays harmless under
docker-image-dev's auto-execution of sambanas2/scripts/ (the target is
idempotent).
"""
import runpy
import sys
from pathlib import Path

_TARGET = (
    Path(__file__).resolve().parent.parent.parent
    / ".github"
    / "scripts"
    / "normalize_changelog_order.py"
)

if __name__ == "__main__":
    sys.argv[0] = str(_TARGET)
    runpy.run_path(str(_TARGET), run_name="__main__")

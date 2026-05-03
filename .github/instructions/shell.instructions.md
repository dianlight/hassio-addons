---
description: "Use when editing shell scripts in add-ons. Covers safe bash patterns, quoting, and repo-specific script practices."
name: "Shell Script Guardrails"
applyTo:
  - "sambanas/**/*.sh"
  - "sambanas2/**/*.sh"
  - "scripts/**/*.sh"
  - "RPiMySensor/**/*.sh"
  - "plex/**/*.sh"
---
# Shell Script Guidelines

- Keep scripts POSIX-compatible when possible; otherwise use bash features intentionally.
- Preserve existing script behavior and command output unless the task requires a behavior change.
- Quote variable expansions by default: use "$var".
- Prefer `[[ ... ]]` over `[ ... ]` in bash scripts.
- Prefer `$(...)` over backticks.
- Validate external tools before using them in new logic (`command -v toolname >/dev/null`).
- Avoid destructive commands without explicit user intent.

## Error Handling

- For new scripts, prefer strict mode near the top:
  - `set -euo pipefail`
- For existing scripts, introduce strict mode only if it will not break current flow.
- Emit clear error messages to stderr before exiting on validation failures.

## Repository-Specific Notes

- Build-related scripts may run for a long time; avoid adding logic that aborts normal long-running build steps.
- Keep architecture handling compatible with existing mappings in [build.sh](../../build.sh).
- If script changes affect user behavior, update the add-on docs in the same project folder.

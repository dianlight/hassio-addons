---
description: "Use when updating README.md, DOCS.md, or CHANGELOG.md for any add-on. Enforces per-add-on isolation and changelog consistency."
name: "Add-on Documentation Consistency"
applyTo:
  - "**/README.md"
  - "**/DOCS.md"
  - "**/CHANGELOG.md"
---
# Documentation Guidelines

- Keep documentation self-contained per add-on.
- Do not copy feature descriptions from one add-on into another.
- Match documentation to the add-on lifecycle state:
  - `sambanas` is maintenance mode.
  - `sambanas2` is active development.
  - `RPiMySensor` and `plex` are deprecated/legacy.

## Required Updates

When behavior, configuration, or services change in an add-on, update all relevant files in that same add-on directory:
- `README.md`: user-visible behavior, install, requirements, status.
- `DOCS.md`: configuration options, examples, service behavior.
- `CHANGELOG.md`: Added/Changed/Fixed/Removed/Breaking Changes as applicable.

## Changelog Format

- Follow the repository template in [.github/CHANGELOG_TEMPLATE.md](../CHANGELOG_TEMPLATE.md).
- Keep entries specific and actionable; include migration notes for breaking changes.

## Validation

- Ensure examples reflect current config keys and defaults.
- Ensure links are local to the same add-on unless intentionally pointing to repository-level docs.

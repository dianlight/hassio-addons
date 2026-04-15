---
description: "Generate add-on release notes and changelog entries from current changes or a provided diff summary."
name: "Release Notes Generator"
argument-hint: "Addon name and optional context (for example: sambanas2 from current branch diff)"
agent: "agent"
---
Generate release notes for the specified add-on using the current workspace changes and any user-provided context.

Requirements:
- Use the changelog structure from [.github/CHANGELOG_TEMPLATE.md](../CHANGELOG_TEMPLATE.md).
- Keep notes scoped to one add-on unless explicitly asked to summarize multiple add-ons.
- Include sections only when they have content:
  - Added
  - Changed
  - Fixed
  - Removed
  - Breaking Changes
- If a change might require migration steps, add a short Migration Notes section.
- Keep language concise and user-facing.

Output format:
1. Suggested version bump with rationale.
2. Changelog entry in markdown, ready to paste.
3. Short PR summary (3-6 bullets).
4. Any follow-up documentation files that should be updated.

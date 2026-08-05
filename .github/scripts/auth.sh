#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────
# .github/scripts/auth.sh
# Shared command-parsing and authorization gate for OpenCode workflows.
#
# Usage:
#   .github/scripts/auth.sh <comment_body>
#
# Command syntax:
#   /oc  [review|implement <info>|task [<task>]|retry]  → Go (paid) model
#   /ocf [review|implement <info>|task [<task>]|retry]  → Free model
#
# Outputs (via GITHUB_OUTPUT):
#   IS_OC_COMMAND=true|false
#   TIER=go|free            (free when /ocf is used, go otherwise)
#   SUBCOMMAND=review|implement|task|discuss|retry|none
#   TASK_ARGS=<text after the subcommand, if any>
# ─────────────────────────────────────────────────────────────────────

COMMENT_BODY="${1:-}"

# Normalize: trim leading/trailing whitespace
TRIMMED=$(echo "$COMMENT_BODY" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

IS_OC="false"
TIER="go"
SUBCOMMAND="none"
TASK_ARGS=""

# Tier detection. /ocf must be matched before /oc (since /ocf starts with /oc).
if [[ "$TRIMMED" =~ ^/ocf([[:space:]]|$) ]]; then
  IS_OC="true"
  TIER="free"
  # Normalize /ocf → /oc so the subcommand patterns below are shared
  TRIMMED="/oc${TRIMMED:4}"
elif [[ "$TRIMMED" =~ ^/oc ]]; then
  IS_OC="true"
fi

if [[ "$IS_OC" == "true" ]]; then
  # Order matters: more specific patterns first
  if [[ "$TRIMMED" =~ ^/oc[[:space:]]+retry[[:space:]]*$ ]]; then
    SUBCOMMAND="retry"
  elif [[ "$TRIMMED" =~ ^/oc[[:space:]]+implement[[:space:]]+(.*) ]]; then
    SUBCOMMAND="implement"
    TASK_ARGS="${BASH_REMATCH[1]}"
  elif [[ "$TRIMMED" =~ ^/oc[[:space:]]+implement[[:space:]]*$ ]]; then
    SUBCOMMAND="implement"
  elif [[ "$TRIMMED" =~ ^/oc[[:space:]]+task[[:space:]]+(.*) ]]; then
    SUBCOMMAND="task"
    TASK_ARGS="${BASH_REMATCH[1]}"
  elif [[ "$TRIMMED" =~ ^/oc[[:space:]]+task[[:space:]]*$ ]]; then
    SUBCOMMAND="task"
  elif [[ "$TRIMMED" =~ ^/oc[[:space:]]+review($|[[:space:]]) ]]; then
    SUBCOMMAND="review"
  elif [[ "$TRIMMED" =~ ^/oc[[:space:]]*$ ]] || [[ "$TRIMMED" =~ ^/oc$ ]]; then
    SUBCOMMAND="discuss"
  else
    # /oc with unrecognized subcommand — default to discuss
    SUBCOMMAND="discuss"
  fi
fi

{
  echo "IS_OC_COMMAND=$IS_OC"
  echo "TIER=$TIER"
  echo "SUBCOMMAND=$SUBCOMMAND"
} >> "$GITHUB_OUTPUT"

# Multi-line args via heredoc delimiter
if [[ -n "$TASK_ARGS" ]]; then
  {
    echo "TASK_ARGS<<OCAUTH_EOF"
    echo "$TASK_ARGS"
    echo "OCAUTH_EOF"
  } >> "$GITHUB_OUTPUT"
else
  echo "TASK_ARGS=" >> "$GITHUB_OUTPUT"
fi

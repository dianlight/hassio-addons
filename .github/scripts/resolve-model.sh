#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────
# .github/scripts/resolve-model.sh
# Resolves the model for an OpenCode workflow step from the central model
# config (data/model-config.json) maintained by opencode-maintenance.
#
# Usage:
#   .github/scripts/resolve-model.sh <workflow> <job> <tier>
#
#   workflow  - workflow file stem (e.g. opencode-pr-review)
#   job       - job id inside that workflow (e.g. review, process-4)
#   tier      - go | free
#
# The central config is the single source of truth: there are no default
# models. If no model can be resolved the step fails hard and the workflow
# stops — a missing config is an error, never a silent fallback.
#
# Resolution order:
#   1. local data/model-config.json (upstream maintenance workflow)
#   2. cached remote config in $RUNNER_TEMP
#   3. raw.githubusercontent.com/dianlight/opencode-actions/main/data/model-config.json
#
# Outputs (via GITHUB_OUTPUT):
#   MODEL          - resolved model for the requested tier
#   MODEL_GO       - resolved Go model
#   MODEL_FREE     - resolved free model
#   CONFIG_SOURCE  - local|cache|remote
# ─────────────────────────────────────────────────────────────────────

WORKFLOW="${1:-}"
JOB="${2:-}"
TIER="${3:-go}"

if [[ -z "$WORKFLOW" || -z "$JOB" ]]; then
  echo "::error::Usage: resolve-model.sh <workflow> <job> <tier>" >&2
  exit 2
fi

CONFIG_URL="https://raw.githubusercontent.com/dianlight/opencode-actions/main/data/model-config.json"
CACHE_FILE="${RUNNER_TEMP:-/tmp}/opencode-model-config.json"

CONFIG_SOURCE=""
CONFIG_FILE=""

if [[ -f "data/model-config.json" ]]; then
  CONFIG_FILE="data/model-config.json"
  CONFIG_SOURCE="local"
elif [[ -f "$CACHE_FILE" ]]; then
  CONFIG_FILE="$CACHE_FILE"
  CONFIG_SOURCE="cache"
elif curl -fsSL --connect-timeout 5 --max-time 15 "$CONFIG_URL" -o "$CACHE_FILE.tmp" 2>/dev/null; then
  mv -f "$CACHE_FILE.tmp" "$CACHE_FILE"
  CONFIG_FILE="$CACHE_FILE"
  CONFIG_SOURCE="remote"
else
  rm -f "$CACHE_FILE.tmp"
fi

if [[ -z "$CONFIG_FILE" ]]; then
  echo "::error::Central model config unreachable ($CONFIG_URL) and no local/cached copy; cannot resolve a model" >&2
  exit 1
fi

# Read go/free for workflow+job; empty string when the entry is missing.
RESOLVED="$(python3 - "$WORKFLOW" "$JOB" "$CONFIG_FILE" <<'PYEOF'
import json
import sys

workflow, job, path = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(path) as fh:
        data = json.load(fh)
    workflows = data.get("workflows")
    if workflows is not None and not isinstance(workflows, dict):
        raise ValueError("'workflows' must be an object")
    mapping = (workflows or {}).get(workflow)
    if mapping is not None and not isinstance(mapping, dict):
        raise ValueError(f"workflow '{workflow}' must be an object")
    if not mapping:
        entry = {}
    else:
        entry = mapping.get(job)
        if entry is None:
            entry = {}
        elif not isinstance(entry, dict):
            raise ValueError(f"job '{job}' must be an object")
    for key in ("go", "free"):
        value = entry.get(key)
        if value is not None and not isinstance(value, str):
            raise ValueError(f"tier '{key}' must be a string")
except Exception as exc:
    print(f"::error::Invalid or unreadable model config {path}: {exc}", file=sys.stderr)
    sys.exit(4)
print(entry.get("go") or "")
print(entry.get("free") or "")
PYEOF
)" || exit 4
GO_MODEL="$(printf '%s' "$RESOLVED" | sed -n '1p')"
FREE_MODEL="$(printf '%s' "$RESOLVED" | sed -n '2p')"

if [[ "$TIER" == "free" ]]; then
  MODEL="$FREE_MODEL"
else
  MODEL="$GO_MODEL"
fi

if [[ -z "$MODEL" ]]; then
  echo "::error::No model resolved for workflow=$WORKFLOW job=$JOB tier=$TIER (source: $CONFIG_SOURCE); add an entry to data/model-config.json" >&2
  exit 3
fi

{
  echo "MODEL=$MODEL"
  echo "MODEL_GO=$GO_MODEL"
  echo "MODEL_FREE=$FREE_MODEL"
  echo "CONFIG_SOURCE=$CONFIG_SOURCE"
} >> "$GITHUB_OUTPUT"

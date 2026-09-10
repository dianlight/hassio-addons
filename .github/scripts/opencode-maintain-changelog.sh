#!/usr/bin/env bash
# Generic opencode changelog maintenance engine for hassio-addons.
#
# Maintains ONLY <addon>/CHANGELOG.md "## Unreleased" via the opencode CLI,
# following the add-on's own style file (<addon>/.changelog-style.md,
# falling back to .github/CHANGELOG_TEMPLATE.md).
#
# This script NEVER commits: commit-back stays in the calling workflow.
# It is intentionally stored under .github/scripts/ (not <addon>/scripts/),
# because docker-image-dev.yml auto-executes every file in <addon>/scripts/
# at build time.
#
# Usage:
#   opencode-maintain-changelog.sh [ADDON] [MODEL]
#
# Environment:
#   ADDON              Add-on directory (default: sambanas2). Overrides $1.
#   OPENCODE_MODEL     Model for `opencode run`. Overrides $2.
#   DRY_RUN=true       Render the prompt and show the diff stat, but do not
#                      run opencode and do not modify any file.
#   OPENCODE_API_KEY   Required unless DRY_RUN=true (never printed).
#   SKIP_SRAT_FETCH=1  Skip the SRAT changelog download.
#
# Exit codes: 0 = CHANGELOG maintained (or dry-run rendered), 1 = usage/config
# error, 2 = opencode run failed.

set -euo pipefail

ADDON="${ADDON:-${1:-sambanas2}}"
MODEL="${OPENCODE_MODEL:-${2:-}}"
DRY_RUN="${DRY_RUN:-false}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ADDON_DIR="${REPO_ROOT}/${ADDON}"
CHANGELOG_FILE="${ADDON_DIR}/CHANGELOG.md"
CONFIG_FILE="${ADDON_DIR}/config.yaml"
DOCKERFILE="${ADDON_DIR}/Dockerfile"
STYLE_FILE="${ADDON_DIR}/.changelog-style.md"
FALLBACK_STYLE="${REPO_ROOT}/.github/CHANGELOG_TEMPLATE.md"
NORMALIZE_SCRIPT="${SCRIPT_DIR}/normalize_changelog_order.py"
# Workspace-local temp dir: opencode run auto-rejects reads outside the repo
# root (external_directory permission), so /tmp paths fail headless.
# Keep SRAT notes + rendered prompt inside the workspace instead.
TMP_DIR="${REPO_ROOT}/.github/tmp"
SRAT_CHANGELOG="${TMP_DIR}/srat-CHANGELOG-${ADDON}.md"
PROMPT_FILE="${TMP_DIR}/changelog-prompt-${ADDON}.txt"
mkdir -p "${TMP_DIR}"

err() {
  echo "Error: $*" >&2
}

# 1. Validate inputs and prerequisites.
if [[ ! -d "${ADDON_DIR}" ]]; then
  err "add-on directory '${ADDON_DIR}' not found."
  exit 1
fi
if [[ ! -f "${CHANGELOG_FILE}" ]]; then
  err "'${CHANGELOG_FILE}' not found."
  exit 1
fi
if [[ ! -f "${CONFIG_FILE}" ]]; then
  err "'${CONFIG_FILE}' not found."
  exit 1
fi
if [[ "${DRY_RUN}" != "true" ]]; then
  if [[ -z "${MODEL}" ]]; then
    err "no model given. Pass it as \$2 or set OPENCODE_MODEL."
    exit 1
  fi
  if [[ -z "${OPENCODE_API_KEY:-}" ]]; then
    err "OPENCODE_API_KEY is not set."
    exit 1
  fi
fi
if ! command -v git >/dev/null; then
  err "git is not installed."
  exit 1
fi
if ! command -v python3 >/dev/null; then
  err "python3 is not installed (needed for the normalize step)."
  exit 1
fi

# 2. Mask secrets in CI logs (values are never printed).
if [[ -n "${OPENCODE_API_KEY:-}" ]]; then
  echo "::add-mask::${OPENCODE_API_KEY}"
fi
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  echo "::add-mask::${GITHUB_TOKEN}"
fi

# 3. Resolve the style source of truth.
if [[ -f "${STYLE_FILE}" ]]; then
  STYLE_DESC="${ADDON}/.changelog-style.md"
else
  STYLE_FILE="${FALLBACK_STYLE}"
  STYLE_DESC=".github/CHANGELOG_TEMPLATE.md (fallback; ${ADDON} has no .changelog-style.md)"
fi
echo "Style source: ${STYLE_DESC}"

# 4. Fetch the SRAT changelog for AI curation (opt-in per add-on).
SRAT_STATUS="unavailable"
SRAT_VERSION=""
if [[ "${SKIP_SRAT_FETCH:-0}" == "1" ]]; then
  echo "SKIP_SRAT_FETCH=1, skipping SRAT changelog download."
elif [[ -f "${DOCKERFILE}" ]] && SRAT_VERSION="$(grep -m1 'ARG SRAT_VERSION=' "${DOCKERFILE}" | cut -d= -f2 | tr -d '"')"; then
  echo "SRAT_VERSION=${SRAT_VERSION}"
  if curl --silent --fail --location \
    "https://raw.githubusercontent.com/dianlight/srat/${SRAT_VERSION}/CHANGELOG.md" \
    -o "${SRAT_CHANGELOG}"; then
    echo "SRAT changelog fetched."
    SRAT_STATUS="available at ${SRAT_CHANGELOG}"
  else
    echo "::warning::Could not fetch SRAT changelog for ${SRAT_VERSION}; AI will note the version without curated items."
  fi
else
  echo "No ARG SRAT_VERSION in ${DOCKERFILE:-<no Dockerfile>}; skipping SRAT curation."
fi

# 5. Render the opencode prompt (single source of truth lives here).
cat > "${PROMPT_FILE}" <<PROMPT_EOF
Maintain ONLY ${ADDON}/CHANGELOG.md ## Unreleased per ${STYLE_DESC}
(emoji sections, RC versions, no dates; config.yaml:version is source of truth).
You run non-interactively in the repo root. Edit that one file only; do not commit.
Steps:
1. Diff origin/master...HEAD scoped to ${ADDON}/ (features, fixes, chores, breaking, migration notes).
2. SRAT (no dedicated section, ever) — status for this run: ${SRAT_STATUS}.
   - Read Dockerfile ARG SRAT_VERSION; the full upstream notes are at
     ${SRAT_CHANGELOG} (fetched by the previous step; fall back to
     https://raw.githubusercontent.com/dianlight/srat/<ver>/CHANGELOG.md).
   - Add ONE Chore bullet referencing the version with a link to the full log:
     \`- Update SRAT to [v<ver>](https://github.com/dianlight/srat/blob/<ver>/CHANGELOG.md)\`.
   - Report only important user-facing SRAT changes inside the normal
     ### ✨ Features / ### 🐛 Bug Fixes sections, each suffixed with
     \`(from SRAT v<ver>)\`. Drop internal churn, Thanks/Roadmap noise and
     duplicates of add-on bullets. If the SRAT fetch failed, keep just
     the Chore version bullet.
   - Never create a ### 🐭 Features from SRAT section.
   - Skip this step entirely when Dockerfile has no ARG SRAT_VERSION.
3. Version rules (C=config.yaml:version, H=first ## != Unreleased):
   - C==H: append to ## Unreleased only (Us1/Us4). Never bump versions here.
   - C not in file + Unreleased non-empty: promote Unreleased -> ## C, leave new empty ## Unreleased (Us2/Us3).
   - C in older ##: no duplication; ensure ## Unreleased exists.
   - Never create -beta/-dev headers here; never add/remove ## Unreleased in a way that leaves two heads.
4. Section order: in the first versioned release put ### 🙏 Thanks first
   and ### 🚨 Notes second (a deterministic step re-sorts them anyway).
5. Keep it concise and user-facing. Do not touch config.yaml, Dockerfile, or translations.
PROMPT_EOF
echo "Prompt rendered to ${PROMPT_FILE}"

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "--- DRY RUN: prompt start ---"
  cat "${PROMPT_FILE}"
  echo "--- DRY RUN: prompt end ---"
  echo "--- DRY RUN: scoped diff stat ---"
  git -C "${REPO_ROOT}" diff --stat "origin/master...HEAD" -- "${ADDON}/" || true
  echo "Dry run complete, no files modified."
  exit 0
fi

# 6. Install opencode CLI if missing (workflow also has an install step;
#    this keeps local runs reproducible).
if ! command -v opencode >/dev/null; then
  echo "opencode CLI not found, installing..."
  curl -fsSL https://opencode.ai/install | bash
  export PATH="${HOME}/.opencode/bin:${PATH}"
fi

# 7. Maintain CHANGELOG.md via the CLI (edits the file, never commits).
OPENCODE_DISABLE_AUTOUPDATE="true" opencode run \
  --model "${MODEL}" \
  --agent build \
  "$(cat "${PROMPT_FILE}")" || {
  err "opencode run failed."
  exit 2
}

# 8. Normalize Thanks/Notes order (deterministic, idempotent).
python3 "${NORMALIZE_SCRIPT}" "${CHANGELOG_FILE}"

# 9. Report what changed; committing is the caller's job.
git -C "${REPO_ROOT}" diff --stat -- "${ADDON}/CHANGELOG.md" || true
echo "Done. ${ADDON}/CHANGELOG.md maintained (not committed)."

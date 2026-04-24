# Builder Migration Plan (Docker BuildKit)

## Goal
Migrate this repository from the retired Home Assistant legacy builder flow to the new Docker BuildKit based flow described in the Home Assistant developer blog (2026-04-02), with a complete file-by-file implementation and low-risk validation strategy.

This document remains a planning artifact (no implementation in this phase).

## Inputs Used
- Home Assistant blog post: Migrating app builds to Docker BuildKit (2026-04-02)
- Existing repository workflows and scripts
- Current repository state on branch `devrelease/sambanas2`
- HA developer docs: https://developers.home-assistant.io/docs/apps/publishing
- HA builder repo README: https://github.com/home-assistant/builder
- HA apps-example reference workflow: https://github.com/home-assistant/apps-example/blob/main/.github/workflows/builder.yaml
- HA `build-image` action interface: https://github.com/home-assistant/builder/actions/build-image/action.yml

## HA Best Practice Review — Key Findings (2026-04-24)

Review against official HA documentation revealed 4 material misalignments in earlier plan versions. They are captured here and corrected throughout the WPs below.

### Finding 1 — Target GitHub Actions are wrong
The plan previously listed `docker/setup-qemu-action`, `docker/setup-buildx-action`, `docker/login-action`, `docker/build-push-action` as the migration targets. **This is not the HA recommended approach.**

The HA official replacement for `home-assistant/builder@master` is a set of NEW COMPOSITE ACTIONS within the same builder repo, pinned to `@2026.03.2`:
- `home-assistant/builder/actions/prepare-multi-arch-matrix` — takes explicit `architectures` JSON array + `image-name`; outputs GitHub Actions build matrix. **Does NOT read config.yaml** — the workflow must extract the arch list first (e.g., `yq e '.arch | @json' config.yaml`).
- `home-assistant/builder/actions/build-image` — single-arch BuildKit build with auto-injection; pushes per-arch image as `{registry-prefix}/{arch}-{image-name}:{tag}`
- `home-assistant/builder/actions/publish-multi-arch-manifest` — combines per-arch images into final multi-arch manifest `{registry-prefix}/{image-name}:{tag}`; handles its own registry login
- `home-assistant/builder/actions/cosign-verify` — verifies cosign signatures; used internally by `build-image`, also available standalone

`docker/` actions are the generic fallback if HA composite actions are not used. The HA composite actions are preferred because they handle several concerns automatically (see Finding 3).

### Finding 2 — Registry target: HA best practice is GHCR, not Docker Hub
The HA official docs and `apps-example` workflow use **GHCR (`ghcr.io`)** with `GITHUB_TOKEN`. The `build-image` action defaults to `container-registry: "ghcr.io"`.

Current `dianlight/hassio-addons` workflows push to **Docker Hub** (`DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN`). Docker Hub is not HA standard. Migration options:
- **Option A (HA best practice)**: migrate to GHCR — uses `GITHUB_TOKEN`, no additional secrets. Breaking change for users (image URL changes from `docker.io/dianlight/...` to `ghcr.io/dianlight/...`).
- **Option B (backward compatible)**: keep Docker Hub — override `container-registry: docker.io` in `build-image` and pass `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN`. Non-standard but supported.

**This is an open decision — must be locked in WP0 (decision #9).**

### Finding 3 — BUILD_ARCH and BUILD_VERSION are AUTO-INJECTED by `build-image`
The plan previously required manual `--build-arg BUILD_ARCH=aarch64` per platform and complex `BUILD_VERSION` sourcing. **These are no longer needed when using HA composite actions:**

| ARG | Plan's approach | Reality with `build-image` |
|---|---|---|
| `BUILD_ARCH` | Manual `--build-arg` per matrix row, mapping arm64→aarch64 | **Auto-injected** from `arch` input using HA conventions (amd64/aarch64) |
| `BUILD_VERSION` | Source from `steps.prepare_yaml_values.outputs.EXTRACTED_BASE_VERSION` | **Auto-injected** from `version` input |
| `org.opencontainers.image.created` | Manual `BUILD_DATE` | **Auto-generated** as OCI label |
| `org.opencontainers.image.source` | Manual `BUILD_REPOSITORY` | **Auto-generated** as OCI label |
| `org.opencontainers.image.version` | Manual `BUILD_VERSION` label | **Auto-generated** from `version` input |
| `io.hass.arch` | Manual label | **Auto-generated** from `arch` input |
| `io.hass.version` | Manual label | **Auto-generated** from `version` input |

**Still requires manual input via `labels` and `build-args` to `build-image`:**
- `BUILD_FROM` → via `build-args` (per-arch base image)
- `io.hass.name` → via `labels` (from `config.yaml` `.name`)
- `io.hass.description` → via `labels` (from `config.yaml` `.description`)
- `io.hass.type=app` → via `labels` (hardcoded)

### Finding 4 — Cosign is BUILT-IN to `build-image` (default: true)
The plan previously required separate `sigstore/cosign-installer` + `cosign sign` steps. With `build-image`:
- `cosign` input defaults to `"true"` — signing is automatic when pushing
- The action handles retry logic (5 attempts, exponential backoff)
- `id-token: write` permission is still required
- `cosign-identity` defaults to the current repo pattern automatically
- The separate cosign steps are **not needed** when using `build-image`

## Scope
- In scope:
  - `sambanas`
  - `sambanas2`
  - GitHub Actions workflows for dev/pr/pre-release build and publish
  - Local/manual build and test scripts
  - `image` field conventions in addon config
  - build metadata currently stored in `build.yaml`
- Out of scope for this plan phase:
  - Actual code/workflow edits
  - Functional feature changes unrelated to builder migration

## Planned MCP and Permission Model (Full List)

**Current session state: No GitHub MCP available. All GitHub operations use `gh` CLI exclusively.**

MCP tool groups (planned, not yet active in this session):
- Repository creation and branch management MCP:
  - fork repository
  - create branch
  - commit/push orchestration support
- Pull request management MCP:
  - create PR
  - update PR
  - read PR status/comments
- GitHub Actions management MCP:
  - list workflows/runs/jobs/artifacts
  - get workflow run details
  - rerun/cancel workflow runs
- Repository information/search MCP:
  - read files/metadata
  - search tags/releases/commits for parity checks

Until MCP is available, all tasks marked `Autonomous` via MCP fall back to GitHub CLI.

Automation path (active — `gh` CLI):
- GitHub CLI via terminal automation (`gh`) is the primary automation path for all GitHub operations.
- Typical commands used in this plan:
  - `gh repo fork <original-repo-url> --fork-name <new-name> --clone`
  - `gh pr create ...`
  - `gh pr edit ...`
  - `gh pr list ...`
  - `gh run list|view|rerun ...`

Permissions and authorization required:
- GitHub token scopes:
  - `repo` (code read/write and PR operations)
  - `workflow` (trigger/rerun/cancel workflow runs)
  - PR write permissions in both fork and upstream
- Repository-level permissions:
  - write access to fork repository
  - branch creation/push permissions on migration branches
  - PR creation permission against upstream default branch policy
- Workflow/runtime permissions:
  - permission to execute workflows in fork and upstream
  - permission to access workflow logs/artifacts for validation evidence
- Registry permissions:
  - non-production push credentials for canary rehearsal
  - production namespace credentials (manual authorization gate before use)
- Manual-only policy gates:
  - GitHub secrets provisioning in repository settings
  - CODEOWNERS/security/release approvals where branch protection requires them
  - final merge authorization on protected branches

CLI prerequisites:
- GitHub CLI installed on runner/workstation where automation is executed.
- Authenticated gh session with required scopes (`gh auth status` must be healthy).

Operational note:
- If any permission above is missing, affected WP tasks are blocked and remain manual until access is granted.
- Where MCP is not available, use GitHub CLI to keep tasks automated when permissions are present.

## Current State Analysis

### 1. Legacy builder dependencies
- Root local build entrypoint `build.sh` invokes legacy arch-specific builder images:
  - `ghcr.io/home-assistant/${arch}-builder:latest`
- CI build workflows use retired action:
  - `.github/workflows/docker-image-dev.yml`: `home-assistant/builder@master`
  - `.github/workflows/docker-image-pr.yaml`: `home-assistant/builder@master`

### 2. Build metadata source of truth split
- `sambanas/build.yaml` defines `build_from` and signing identity metadata.
- `sambanas2/build.yaml` defines `build_from` and `args` (`HA_CLI_VERSION`, `SRAT_VERSION`, `SAMBA_VERSION`).
- Dockerfiles still depend on builder-populated metadata args (`BUILD_FROM`, `BUILD_*`).

### 3. Local test drift
- `sambanas/test/*` and `sambanas2/test/*` still use old `homeassistant/armv7-base` patterns.
- `sambanas2/test/*` is currently mismatched (copied from `sambanas` values and image names).

### 4. Secondary script coupling
- `sambanas2/scripts/update_srat_changelog.sh` reads SRAT version from `build.yaml` (`.args.SRAT_VERSION`).

### 5. Config/image conventions
- `sambanas/config.yaml` currently uses arch-prefixed image template (`dianlight/{arch}-addon-sambanas`).
- `sambanas2/config.yaml` image field is **active** (`dianlight/{arch}-addon-sambanas2`), not commented out — both use incompatible arch-prefixed template syntax.

### 6. AUTO-INJECTED BUILD_* args — legacy builder vs HA composite `build-image`

The legacy builder auto-populates all BUILD_* args. With HA's new `build-image` action, several are still auto-handled; only `BUILD_FROM` and metadata labels need manual input.

| ARG / Label | Legacy builder source | `build-image` action | Action required |
|---|---|---|---|
| `BUILD_FROM` | `build.yaml` `.build_from.<arch>` | **NOT auto-injected** | Pass via `build-args: BUILD_FROM=<base>` |
| `BUILD_ARCH` | `--amd64`/`--aarch64` flag | **Auto-injected** from `arch` input (HA names) | None — do NOT add manually |
| `BUILD_VERSION` | `config.yaml` `.version` | **Auto-injected** from `version` input | None — pass `version` input only |
| `org.opencontainers.image.created` | Build-time UTC | **Auto-generated** as OCI label | None |
| `org.opencontainers.image.source` | GitHub repo path | **Auto-generated** as OCI label | None |
| `org.opencontainers.image.version` | Config version | **Auto-generated** from `version` input | None |
| `io.hass.arch` | `--amd64`/`--aarch64` flag | **Auto-generated** from `arch` input | None |
| `io.hass.version` | Config version | **Auto-generated** from `version` input | None |
| `io.hass.name` | `config.yaml` `.name` | **NOT auto-generated** | Pass via `labels` input |
| `io.hass.description` | `config.yaml` `.description` | **NOT auto-generated** | Pass via `labels` input |
| `io.hass.type` | Hardcoded `addon`/`app` | **NOT auto-generated** | Pass `io.hass.type=app` via `labels` |

**Summary: only 4 items require manual input to `build-image`**: `BUILD_FROM` (build-arg), `io.hass.name`, `io.hass.description`, `io.hass.type` (all three via the `labels` input).

### 7. BUILD_ARCH value at runtime — handled by `build-image`, not workflow matrix

`BUILD_ARCH` is used in runtime `RUN` blocks (not just labels) to select binaries:
- `sambanas2/Dockerfile`: lines 276, 290, 294-295 — HA CLI binary, SRAT binary, APFS gate
- `sambanas/Dockerfile`: lines 28, 103, 112 — HA CLI binary, poetry flag, APFS gate

All shell logic expects `aarch64` (HA convention), not `arm64` (Docker/OCI standard). With `build-image`, the `arch` input uses HA conventions (`amd64`/`aarch64`) and `BUILD_ARCH` is auto-injected with the correct HA value. No manual mapping needed. If the `docker/build-push-action` fallback is used, inject `--build-arg BUILD_ARCH=aarch64` explicitly (see decision #5).

### 8. ARG defaults missing — silent build failures if build.yaml is removed early

`sambanas2/Dockerfile` declares these ARGs with no `=default` values:
- `ARG HA_CLI_VERSION` (line 9)
- `ARG SRAT_VERSION` (line 157)
- `ARG SAMBA_VERSION` (line 160)

Removing `build.yaml` before adding defaults causes empty-string args that produce broken download URLs at build time (curl failure, not a Dockerfile syntax error). Always add defaults before removing `build.yaml`.

### 9. Cosign permission gap (latent CI bug)

`docker-image-pr.yaml` passes `--cosign` flag to the legacy builder but lacks `id-token: write` in its `permissions` block. Keyless OIDC signing requires this permission. With `build-image` (cosign built-in), the missing permission will cause the signing step inside the action to fail. Fix: add `id-token: write` to all jobs that call `build-image` with `cosign: true`.

`sambanas2/build.yaml` had the cosign block commented out; `sambanas/build.yaml` had it active. After migration, cosign is enabled for both addons on publish paths (decision #6). Dev workflow uses `cosign: false` to preserve current unsigned-dev behavior.

### 10. Renovate tracking gap after build.yaml removal

The SRAT version custom manager (`renovate.json`) targets only `//build.yaml$/`. After migration to Dockerfile ARG defaults, this manager must also cover `//Dockerfile$/` or SRAT version auto-updates will silently stop working. The HA CLI manager already covers both files; only SRAT needs updating.

### 11. Registry authentication — current Docker Hub, migrating to GHCR

**Current state:** Both CI workflows push to Docker Hub using `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN` secrets. The legacy builder handles `docker login` internally. `GITHUB_TOKEN` is only used in `gh pr create` calls.

**After migration (decision #9A — GHCR):**
- `build-image` and `publish-multi-arch-manifest` authenticate to `ghcr.io` via `container-registry-password: ${{ secrets.GITHUB_TOKEN }}`
- `GITHUB_TOKEN` automatically has `packages: write` when the job declares `packages: write` permission
- No Docker Hub secrets needed in CI after migration
- `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN` secrets can be retired from the repository after validation
- `registry-prefix` defaults to `ghcr.io/${{ github.repository_owner }}` = `ghcr.io/dianlight`

### 12. `mergerelease/<addon>` branch — force-push side-effect of dev workflow

The dev workflow (`docker-image-dev.yml`) includes a post-build step (runs only when `scripts/` directory is present) that:
1. Stages all modified files (including `config.yaml` after version mutation by `yq`)
2. Commits with message `ci(script) Commit all automatic changes for mergerelease in <addon>`
3. Creates/overwrites local branch `mergerelease/<addon>`
4. **Force-pushes** to `origin/mergerelease/<addon>`

After BuildKit migration, the `config.yaml` mutation step still runs (it's independent of the builder). The `mergerelease` step must continue to work. The only risk is if the migration changes which files are modified before this step runs. The step must be verified to still stage + commit the same set of auto-generated changes.

## Target State (Migration End State)
- No usage of retired `home-assistant/builder@master` action or `ghcr.io/home-assistant/*-builder` container images.
- Dockerfile (plus CI workflow inputs) is the only source for build args that were in `build.yaml`.
- Build/publish uses HA composite actions pinned to `@2026.03.2`:
  - `home-assistant/builder/actions/prepare-multi-arch-matrix`
  - `home-assistant/builder/actions/build-image` (per arch; handles BUILD_ARCH, BUILD_VERSION, OCI labels, cosign automatically)
  - `home-assistant/builder/actions/publish-multi-arch-manifest` (multi-arch manifest creation)
- Registry target: **GHCR (`ghcr.io/dianlight/`)** using `GITHUB_TOKEN` with `packages: write` permission (decision #9, locked).
- Addon config `image` uses GHCR generic multi-arch naming: `ghcr.io/dianlight/addon-sambanas` and `ghcr.io/dianlight/addon-sambanas2`.
- Note on intermediate naming: `build-image` pushes per-arch images as `ghcr.io/dianlight/{arch}-{name}:{tag}` during the build phase; `publish-multi-arch-manifest` assembles these into the final `ghcr.io/dianlight/{name}:{tag}` manifest.
- Local build/test uses `docker buildx build` directly (HA composite actions are CI-only).

## File-By-File Migration Matrix (Every Touched File)

### A) CI workflows (required)
1. `.github/workflows/docker-image-dev.yml`
- Why touched: remove legacy `home-assistant/builder@master` publish path.
- Current behavior: publishes to Docker Hub (`--docker-hub dianlight`) with `--no-latest`. Uses `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN` secrets. After the build step, conditionally creates/force-pushes a `mergerelease/<addon>` branch with auto-committed workflow changes. No cosign on dev.
- Planned change (HA best practice):
  - Replace legacy builder step with `prepare-multi-arch-matrix` → matrix of `build-image` (per arch) → `publish-multi-arch-manifest`.
  - Keep existing branch/version/name mutation logic (yq steps) unchanged and before the build step.
  - Pass `version: EXTRACTED_BASE_VERSION-dev.<run_number>` to `build-image` (`BUILD_VERSION` auto-injected).
  - Pass `BUILD_FROM` via `build-args`; pass `io.hass.name/description/type` via `labels`.
  - Registry: GHCR (`GITHUB_TOKEN`) or Docker Hub (decision #9). Add `packages: write` permission if GHCR.
  - Preserve `--no-latest` semantics: use versioned tag only.
  - Preserve `mergerelease/<addon>` force-push step — verify unchanged after migration.
  - `cosign: false` on dev workflow to match current behavior (no signing on dev builds).

2. `.github/workflows/docker-image-pr.yaml`
- Why touched: remove legacy builder publish path.
- Current behavior: **publishes** to Docker Hub on every non-draft PR to master and `workflow_dispatch`. Signs images (`--cosign`) but is missing `id-token: write` permission (latent bug). No `--no-latest` flag, so PR builds update `:latest`.
- Planned change (HA best practice):
  - Replace legacy builder call with `prepare-multi-arch-matrix` → matrix of `build-image` → `publish-multi-arch-manifest`.
  - Keep changelog/version consistency gate unchanged.
  - `build-image` with `cosign: true` (default) replaces explicit `--cosign` flag. Fix `id-token: write` + `packages: write` permissions.
  - Registry: same decision as #9. Pass `GITHUB_TOKEN` (GHCR) or `DOCKERHUB_*` (Docker Hub).
  - No `--no-latest` behavior to change — preserve current (PR publishes latest).
  - Keep manual `workflow_dispatch` addon selection behavior.

3. `.github/workflows/docker-image-pre.yml`
- Why touched: compatibility validation only.
- Planned change:
  - Minimal/no build logic change expected.
  - Validate that prerelease automation remains compatible with updated image naming conventions.
  - During migration rehearsal/testing, beta-repo pull requests created by automation must be draft-only to simulate behavior without promoting review/merge flow.
  - Implementation hint: use `gh pr create --draft ...` in the beta-repo PR creation step; if an existing PR is found and must remain draft, enforce draft state before finishing the job.
  - Update comments if they mention retired builder assumptions.

### B) Dockerfiles and addon metadata (required)
4. `sambanas/Dockerfile`
- Why touched: ensure default ARG strategy for BuildKit flow and reduce dependence on external `build.yaml`.
- Planned change:
  - Define robust defaults for `BUILD_FROM` and optional metadata args where safe.
  - Confirm no hard runtime dependency on legacy auto-populated values.
  - Keep current labels but make values deterministic from workflow-provided args.

5. `sambanas2/Dockerfile`
- Why touched: absorb `build.yaml` args into Dockerfile defaults.
- Planned change:
  - Add default values for `HA_CLI_VERSION`, `SRAT_VERSION`, `SAMBA_VERSION` currently stored in `build.yaml`.
  - Confirm `BUILD_FROM` default strategy for amd64/aarch64.
  - Keep labels; pass metadata args explicitly from CI if needed.

6. `sambanas/config.yaml`
- Why touched: image naming migration — registry and naming both change.
- Planned change:
  - Change `image: dianlight/{arch}-addon-sambanas` → `image: ghcr.io/dianlight/addon-sambanas` (GHCR, generic multi-arch, no arch prefix in user-facing name).

7. `sambanas2/config.yaml`
- Why touched: image naming migration — registry and naming both change.
- Planned change:
  - Change active `image: dianlight/{arch}-addon-sambanas2` (line 68) → `image: ghcr.io/dianlight/addon-sambanas2` (GHCR, generic multi-arch).

8. `sambanas/build.yaml`
- Why touched: deprecation/removal after parity.
- Planned change:
  - Keep during transition for rollback safety.
  - Remove once Dockerfile/workflow parity and validations are green.

9. `sambanas2/build.yaml`
- Why touched: deprecation/removal after parity.
- Planned change:
  - Keep during transition for rollback safety.
  - Remove once script and Dockerfile have migrated source-of-truth.

### C) Local tooling and scripts (required)
10. `build.sh`
- Why touched: local entrypoint still calls retired builder container.
- Planned change:
  - Replace legacy builder invocation with `docker buildx build` workflow.
  - Preserve addon discovery from `config.yaml`/`config.json`.
  - Keep architecture selection behavior, but align to supported targets.
  - Add explicit `--load` (local test) and optional `--push` (opt-in) modes.

11. `sambanas/test/buildLocal.sh`
- Why touched: outdated base image and args.
- Planned change:
  - Move to new build args and modern base image conventions.
  - Align tags with generic naming and selected arch.

12. `sambanas/test/runLocal.sh`
- Why touched: outdated build invocation and image name.
- Planned change:
  - Build and run image via updated naming and args.
  - Keep existing test data mount behavior.

13. `sambanas2/test/buildLocal.sh`
- Why touched: currently copied from `sambanas` and incorrect for addon2.
- Planned change:
  - Rebuild script with `sambanas2` paths, tags, and Dockerfile args.
  - Cover amd64/aarch64 local simulation strategy where possible.

14. `sambanas2/test/runLocal.sh`
- Why touched: currently copied from `sambanas` and incorrect for addon2.
- Planned change:
  - Rebuild run script for `sambanas2` image/tag and options.
  - Keep smoke-run behavior and logs.

15. `sambanas2/scripts/update_srat_changelog.sh`
- Why touched: references `build.yaml` for SRAT version.
- Planned change:
  - Read SRAT version from `sambanas2/Dockerfile` ARG default instead.
  - Keep retry/error handling behavior unchanged.

### D) Repository automation/config (likely required)
16. `.github/renovate.json`
- Why touched: existing regex managers include `build.yaml`; removal would break update flow for versions.
- Planned change:
  - Move/extend regex managers to track version ARGs in Dockerfiles.
  - Remove `build.yaml` references only after migration completion.

17. `README.md` and/or addon docs (`sambanas/README.md`, `sambanas2/README.md`, `sambanas2/test/README.md`)
- Why touched: developer instructions likely reference old local build flow.
- Planned change:
  - Update local build/test instructions to new BuildKit process.
  - Add explicit non-push smoke test commands.

## Work Packages and Execution Detail

## WP0 - Baseline and Decision Capture
Status: **Complete** (2026-04-24)

MCP and permissions needed:
- MCP: none required for decision capture.
- Permission: maintainer-level decision authority for scope/policy lock.

Locked decisions:
1. Migrate both addons (`sambanas`, `sambanas2`).
2. Do not preserve armv7 publish support for `sambanas` in CI target workflow.
3. Use generic multi-arch image naming in `config.yaml`.
4. Execute migration in one PR.
5. **BUILD_ARCH mapping**: `build-image` action auto-injects `BUILD_ARCH` using HA arch names (`amd64`/`aarch64`) from its `arch` input. No manual `--build-arg BUILD_ARCH` needed in the workflow. If the generic `docker/build-push-action` fallback is used instead, manual injection is required.
6. **Cosign**: `build-image` has cosign built-in (`cosign: true` default). No separate `sigstore/cosign-installer` + `cosign sign` steps needed. Fix `id-token: write` permission gap on PR workflow. Enable cosign for both addons (set `cosign: true` explicitly on publish jobs; `cosign: false` on dev workflow to match current behavior).
7. **Image naming breaking change**: rename from `{arch}-addon-sambanas*` arch-prefixed templates to generic single-name multi-arch images. Document as Breaking Change in CHANGELOG; add Migration Notes for users (re-add addon).
8. **Arg name unification**: rename `sambanas/Dockerfile` `CLI_VERSION` to `HA_CLI_VERSION` to match `sambanas2` and Renovate tracking.
9. **Registry target — LOCKED: Option A (GHCR)**. Migrate from Docker Hub to `ghcr.io/dianlight/`. Auth via `GITHUB_TOKEN` with `packages: write` permission — no additional secrets needed. Breaking change for existing HA users (image URL changes from `docker.io/dianlight/...` to `ghcr.io/dianlight/...`, combined with image rename from decision #7). Both breaking changes documented together in CHANGELOG. `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN` secrets are no longer needed in CI after migration.

## WP0.5 - Rehearsal Branch Setup
Status: **Complete** (2026-04-24)

> **Fork constraint (discovered 2026-04-24):** GitHub does not allow `dianlight` to fork `dianlight/hassio-addons` to the same account. The temporary fork strategy is replaced with a **dedicated migration branch** directly in the upstream repo. Isolation is maintained because `migration/*` branches do not match any CI trigger pattern (`devrelease/*`, `prerelease/*`, or PR-to-master), so no production workflow fires on push to the rehearsal branch.

Permissions needed:
- `gh` CLI with `repo` + `workflow` scopes (already confirmed)
- Branch push rights to `dianlight/hassio-addons` (owner — confirmed)
- `packages: write` via `GITHUB_TOKEN` for GHCR canary pushes (no extra secrets)

Goal:
- Create `migration/buildkit-rehearsal` branch based on upstream `master`.
- Cherry-pick migration plan commits from `devrelease/sambanas2` into the rehearsal branch so the plan document travels with the implementation work.
- Implement all WP1–WP4 changes on this branch.
- Trigger CI by temporarily adding `migration/*` to the dev workflow's branch trigger list (with canary tag override) for Phase 2/3 validation.

Repository/branch model:
- Upstream (source of truth and rehearsal host): `dianlight/hassio-addons`
- Rehearsal branch: `migration/buildkit-rehearsal` (based on `master`)
- Final integration branch: `migration/buildkit-final` → PR to `master`

> **WP6 blocker (discovered 2026-04-24):** `master` has `lock_branch: true` — no PR merges are currently possible. The final merge in WP6 will require temporarily unlocking `master` in repo Settings → Branches. Flag this before WP6 begins.

Tasks:
- [ ] Create and sync temporary fork from upstream `master` (MCP or `gh repo fork <original-repo-url> --fork-name <new-name> --clone`).
- [ ] Mirror only required CI secrets into the fork (least privilege).
- [ ] Configure fork workflows to use non-production publish targets/tags.
- [ ] Configure beta-repo PR automation in test mode to create draft PRs only (simulation safety gate).
- [ ] Implement all migration changes in the fork only.
- [ ] Run full validation sequence in fork:
  - local zero-publish checks
  - CI dry-run checks
  - canary publish checks (temporary namespace)
- [ ] Produce validation evidence bundle:
  - workflow run URLs
  - image tags/manifests produced
  - label parity notes
  - addon smoke test logs

Pre-flight authorization checklist:
- [x] GitHub CLI authenticated as `dianlight` with `repo` + `workflow` scopes (confirmed 2026-04-24).
- [x] Branch push rights to `dianlight/hassio-addons` confirmed (repo owner).
- [x] `migration/*` branches confirmed safe — do not trigger any CI workflow (`devrelease/*`, `prerelease/*`, or PR-to-master patterns only).
- [x] Registry: GHCR via `GITHUB_TOKEN` — no additional secrets required. `packages: write` permission declared in job is sufficient.
- [x] No CODEOWNERS file — 1 approving review required for master PRs (repo owner can self-approve after master is unlocked).
- [x] Canary publish namespace confirmed: `ghcr.io/dianlight/<addon>:migration-canary-<run_number>`.
- [x] Beta-repo (`dianlight/hassio-addons-beta`) PR creation: `pre.yml` has one path without `--draft` — must be fixed in WP1 before triggering any prerelease-path CI.
- [ ] `master` branch unlock confirmed ready for WP6 (currently `lock_branch: true` — must be temporarily unlocked before final merge).
- [ ] Rollback owner and communication channel confirmed (manual — assign before WP5).

GitHub CLI runbook (branch-based rehearsal):
```bash
REHEARSAL_BRANCH="migration/buildkit-rehearsal"

# 1) Verify auth
gh auth status

# 2) Create rehearsal branch from master
git fetch origin master
git checkout -B "$REHEARSAL_BRANCH" origin/master

# 3) Cherry-pick migration plan commits from devrelease/sambanas2
#    (only the planning docs — not the sambanas2 code changes)
git cherry-pick 4da7afc 0d0d6c6 d43fd55 3b630ba 21346f2

# 4) Push rehearsal branch to origin
git push -u origin "$REHEARSAL_BRANCH"

# 5) After applying WP1–WP4 edits, commit and push
git add <changed-files>
git commit -m "feat(buildkit): <wp-description>"
git push origin "$REHEARSAL_BRANCH"

# 6) For CI validation (Phase 2): temporarily add migration/* to dev workflow triggers,
#    override image-tags to canary namespace, then push to trigger CI
git push origin "$REHEARSAL_BRANCH"
gh run list --repo dianlight/hassio-addons --branch "$REHEARSAL_BRANCH" --limit 10
gh run view <run-id> --log

# 7) Beta-repo PRs: always --draft during rehearsal
gh pr create --draft --title "[migration-rehearsal] <description>" --body "..."
```

Exit criteria:
- Rehearsal start gate: all pre-flight authorization checklist items are completed.
- Fork rehearsal complete and green.
- Validation evidence bundle is complete and approved for upstream reintegration.

## WP1 - CI BuildKit Migration Scaffold
Status: **Complete** (2026-04-24)

MCP and permissions needed:
- MCP: repository information/search MCP, PR MCP, GitHub Actions MCP.
- CLI alternative: `gh` for PR and workflow operations.
- Permission:
  - branch write + PR write permissions
  - workflow trigger/rerun permissions
  - security sign-off permission path for signing behavior changes

Files:
- `.github/workflows/docker-image-dev.yml`
- `.github/workflows/docker-image-pr.yaml`
- `.github/workflows/docker-image-pre.yml` (if comments/behavior coupling appears)

Required GitHub Actions (HA composite actions — primary path, pinned to `@2026.03.2`):
- `home-assistant/builder/actions/prepare-multi-arch-matrix` — takes `architectures` (JSON array) + `image-name`; emits matrix. Workflow must extract arch list from `config.yaml` before calling: `yq e '.arch | @json' <CONFIG_FILE>`. Supported values: `amd64`, `aarch64` only.
- `home-assistant/builder/actions/build-image` — per-arch BuildKit build. **Auto-injects** `BUILD_ARCH`, `BUILD_VERSION`, `io.hass.arch`, `io.hass.version`, and standard OCI labels. Cosign built-in (default on). Pushes as `{registry-prefix}/{arch}-{image-name}:{tag}`.
- `home-assistant/builder/actions/publish-multi-arch-manifest` — combines per-arch images into `{registry-prefix}/{image-name}:{tag}` manifest. Handles its own registry login.

Fallback (if HA composite actions are not suitable for any step):
- `docker/setup-qemu-action@v3`, `docker/setup-buildx-action@v3`, `docker/login-action@v3`, `docker/build-push-action@v6`.

Tasks:
- [x] Replace `home-assistant/builder@master` call with the three HA composite actions:
  1. **Extract arch list** from `config.yaml` before calling `prepare-multi-arch-matrix`:
     ```yaml
     - id: get_arch
       run: echo "architectures=$(yq e '.arch | @json' $CONFIG_FILE)" >> $GITHUB_OUTPUT
     ```
  2. `prepare-multi-arch-matrix` with `architectures: ${{ steps.get_arch.outputs.architectures }}` and `image-name: addon-sambanas[2]`
  3. Matrix job calling `build-image` per arch with `push: ${{ inputs.publish }}`
  4. `publish-multi-arch-manifest` to create the multi-arch manifest (publish path only)
- [x] Keep all existing version/name mutation steps (`yq` version writes, `EXTRACTED_BASE_VERSION`) untouched and BEFORE the build step.
- [x] Pass to `build-image`:
  - `arch` — from matrix output (HA convention: `amd64`, `aarch64`)
  - `image-name` — `addon-sambanas` or `addon-sambanas2`
  - `registry-prefix` — `ghcr.io/dianlight`
  - `version` — mutated version (dev: `EXTRACTED_BASE_VERSION-dev.<run_number>`; PR: config version)
  - `build-args: BUILD_FROM=<per-arch base image>` — **only** remaining manual build arg
  - `labels` — `io.hass.name=...\nio.hass.description=...\nio.hass.type=app`
  - `container-registry-password: ${{ secrets.GITHUB_TOKEN }}` — GHCR auth (decision #9)
  - `push: true` on all publish paths
  - `cosign: false` for dev workflow; default (true) for PR workflow
- [x] **Do NOT add `--build-arg BUILD_ARCH`** — auto-injected by `build-image`.
- [x] **Do NOT add separate cosign steps** — `build-image` handles signing internally.
- [x] Set permissions `id-token: write` + `packages: write` on all jobs calling `build-image` with `push: true`.
- [x] Pass `container-registry-password: ${{ secrets.GITHUB_TOKEN }}` to `publish-multi-arch-manifest` as well.
- [x] Preserve `--no-latest` semantics: dev workflow uses versioned `image-tags` only; PR workflow includes `latest` tag.
- [x] Ensure prerelease beta-repo PR creation remains draft-only during rehearsal.
- [x] Remove `CAS_API_KEY` usage — codenotary attestation is not part of the HA signing flow.
- [ ] Verify `mergerelease/<addon>` force-push step still works after migration. *(runtime verification — WP5)*

Exit criteria:
- No references to `home-assistant/builder@master` or `ghcr.io/home-assistant/*-builder`.
- All three HA composite actions used in publish workflows.
- Arch list extracted from `config.yaml` and passed as JSON to `prepare-multi-arch-matrix`.
- `BUILD_ARCH` and `BUILD_VERSION` NOT manually specified.
- `BUILD_FROM` passed via `build-args`; `io.hass.name/description/type` passed via `labels`.
- Registry target is `ghcr.io/dianlight/` with `GITHUB_TOKEN` auth.
- `id-token: write` + `packages: write` on all jobs calling `build-image` with `push: true`.
- `CAS_API_KEY` removed from all workflows.
- `mergerelease/<addon>` force-push step verified still functional.

## WP2 - Dockerfile Parity and Metadata Ownership
Status: Not started

MCP and permissions needed:
- MCP: repository information/search MCP, PR MCP.
- Permission:
  - branch write + PR write permissions
  - maintainer approval for metadata/label/signing semantics

Files:
- `sambanas/Dockerfile`
- `sambanas2/Dockerfile`

Tasks:
- [ ] Add `=default` values to all currently bare `ARG` declarations in both Dockerfiles: `HA_CLI_VERSION`, `SRAT_VERSION`, `SAMBA_VERSION` in `sambanas2/Dockerfile`; `CLI_VERSION` (→ rename to `HA_CLI_VERSION`) in `sambanas/Dockerfile`.
- [ ] Rename `ARG CLI_VERSION` to `ARG HA_CLI_VERSION` in `sambanas/Dockerfile` (and update all references within the file). This unifies arg naming across both addons and restores Renovate tracking.
- [ ] Move `build.yaml` version values into Dockerfile ARG defaults (values sourced from current `build.yaml` at migration time).
- [ ] Ensure `ARG BUILD_FROM`, `ARG BUILD_ARCH`, `ARG BUILD_VERSION` are declared in both Dockerfiles (with safe fallback defaults). CI will provide values via `build-image` auto-injection (`BUILD_ARCH`, `BUILD_VERSION`) and explicit `build-args` (`BUILD_FROM`). Do NOT add `TARGETARCH`-based normalization — `build-image` provides `BUILD_ARCH` using HA arch names directly.
- [ ] Confirm `BUILD_FROM` default strategy: define a safe amd64 default in `ARG BUILD_FROM=ghcr.io/hassio-addons/base:<version>` for local builds; CI always overrides via `--build-arg`.
- [ ] Verify both Dockerfiles can build via BuildKit without `build.yaml` dependency.

Exit criteria:
- Dockerfiles contain/receive all required values for successful build and labeling.
- No bare `ARG` declarations (all have a `=default` value or are explicitly provided by CI).
- Both Dockerfiles use `HA_CLI_VERSION` consistently.

## WP3 - Config and Local Tooling Migration
Status: Not started

MCP and permissions needed:
- MCP: repository information/search MCP, PR MCP.
- Permission:
  - branch write + PR write permissions
  - local environment execution access for smoke tests
  - optional HA runtime access if host-level validation is required

Files:
- `sambanas/config.yaml`
- `sambanas2/config.yaml`
- `build.sh`
- `sambanas/test/buildLocal.sh`
- `sambanas/test/runLocal.sh`
- `sambanas2/test/buildLocal.sh`
- `sambanas2/test/runLocal.sh`

Tasks:
- [ ] Update `image` field in both `config.yaml` files to GHCR generic multi-arch naming (decision #9):
  - `sambanas/config.yaml`: `image: dianlight/{arch}-addon-sambanas` → `image: ghcr.io/dianlight/addon-sambanas`
  - `sambanas2/config.yaml` (line 68): `image: dianlight/{arch}-addon-sambanas2` → `image: ghcr.io/dianlight/addon-sambanas2`
  - This is a double Breaking Change (registry URL + image name) — document both in CHANGELOG.
- [ ] Replace legacy `build.sh` local builder container usage with `docker buildx build`. Add `docker buildx create --use` setup. Add `--load` (local test, no push) and opt-in `--push` modes.
- [ ] Fully rewrite `sambanas2/test/buildLocal.sh` — it is byte-for-byte identical to `sambanas/test/buildLocal.sh` and wrong on 5 counts:
  1. Base image: change from `homeassistant/armv7-base:3.13` → `ghcr.io/hassio-addons/base:<version>`
  2. Arch: change from `armv7` → `amd64` (or `aarch64`; sambanas2 has no armv7 support)
  3. Arg name: `CLI_VERSION` → `HA_CLI_VERSION`
  4. Missing args: add `SRAT_VERSION` and `SAMBA_VERSION`
  5. Tag: change from `armv7-addon-sambanas` → `sambanas2` naming convention
- [ ] Update `sambanas/test/buildLocal.sh`: align base image, arg name (`CLI_VERSION` → `HA_CLI_VERSION`), and tag to new generic naming.
- [ ] Update both `runLocal.sh` scripts to use updated image names.
- [ ] Add non-push smoke test mode (`--load` only, no push by default).
- [ ] Add `docker buildx create --use` setup step and note QEMU/binfmt requirement for cross-arch builds.

Exit criteria:
- Local scripts build and run both addons without legacy builder images.
- `sambanas2/test/buildLocal.sh` is distinct from `sambanas/test/buildLocal.sh` and correct for sambanas2.
- No `armv7` references remain in sambanas2 test scripts.

## WP4 - Dependency Cleanup
Status: Not started

MCP and permissions needed:
- MCP: repository information/search MCP, PR MCP.
- Permission:
  - branch write + PR write permissions
  - maintainer approval for deleting `build.yaml` files

Files:
- `sambanas2/scripts/update_srat_changelog.sh`
- `.github/renovate.json`
- `sambanas/build.yaml`
- `sambanas2/build.yaml`

Tasks:
- [ ] Migrate SRAT version source in `sambanas2/scripts/update_srat_changelog.sh` from `build.yaml` yq path to `sambanas2/Dockerfile` ARG default. Suggested replacement: `srat_version=$(grep -m1 'ARG SRAT_VERSION=' sambanas2/Dockerfile | cut -d= -f2 | tr -d '"')`.
- [ ] Update Renovate SRAT custom manager (`renovate.json`): add `//Dockerfile$/` to `managerFilePatterns` (currently only `//build.yaml$/`). **Must be done before `build.yaml` is deleted** or SRAT auto-updates silently stop.
- [ ] Verify Renovate `HA_CLI_VERSION` manager covers `sambanas/Dockerfile` after the `CLI_VERSION` → `HA_CLI_VERSION` rename in WP2.
- [ ] Remove both `build.yaml` files after successful validation gates (never before Dockerfile defaults and Renovate patterns are verified green).

Exit criteria:
- No runtime or automation dependency on `build.yaml` remains.
- Renovate successfully tracks SRAT version in `sambanas2/Dockerfile`.
- `update_srat_changelog.sh` reads SRAT version from Dockerfile correctly.

## WP5 - Validation, Rollout, and Rollback Readiness
Status: Not started

MCP and permissions needed:
- MCP: GitHub Actions MCP, PR MCP, repository information/search MCP.
- Permission:
  - workflow run/log/artifact access
  - non-production publish credentials for canary
  - manual production publish authorization gate
  - rollback authority assignment

Files:
- `README.md` / addon docs as needed

Tasks:
- [ ] Validate PR build workflow end-to-end for both addons.
- [ ] Validate devrelease publish workflow, tag format, and labels.
- [ ] Validate prerelease sync flow still creates expected PRs/branches.
- [ ] Validate addon image resolution from updated `config.yaml`.
- [ ] Verify key OCI/io.hass labels are present and non-empty on published images (most auto-generated by `build-image`; check the 4 manually-supplied ones specifically):
  ```bash
  # Check all labels on final manifest image
  docker buildx imagetools inspect ghcr.io/dianlight/addon-sambanas2:<tag> --format '{{json .Config.Labels}}' | jq '{name: .["io.hass.name"], desc: .["io.hass.description"], type: .["io.hass.type"], arch: .["io.hass.arch"], ver: .["io.hass.version"], created: .["org.opencontainers.image.created"]}'
  ```
- [ ] Verify multi-arch manifest exists for both platforms:
  ```bash
  docker buildx imagetools inspect <image>:<tag> | grep -E "Platform|Digest"
  ```
- [ ] Verify cosign signature on published GHCR images:
  ```bash
  cosign verify \
    --certificate-identity-regexp 'https://github.com/dianlight/hassio-addons/.*' \
    --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
    ghcr.io/dianlight/addon-sambanas2:<tag>
  ```
- [ ] Confirm per-arch intermediate images also exist in GHCR (expected):
  ```bash
  docker buildx imagetools inspect ghcr.io/dianlight/aarch64-addon-sambanas2:<tag>
  docker buildx imagetools inspect ghcr.io/dianlight/amd64-addon-sambanas2:<tag>
  ```
- [ ] Add Breaking Change entry to CHANGELOG: registry change (`docker.io/dianlight/` → `ghcr.io/dianlight/`) AND image rename (`{arch}-addon-sambanas*` → generic). Document both together.
- [ ] Add Migration Notes section to CHANGELOG with exact re-add instructions for existing HA users (remove old addon, add from new URL).
- [ ] Add/update rollback and troubleshooting notes.

Exit criteria:
- All workflows green with BuildKit-only path publishing to `ghcr.io/dianlight/`.
- `io.hass.name`, `io.hass.description`, `io.hass.type`, `io.hass.arch`, `io.hass.version` all non-empty in final manifest.
- Multi-arch manifest confirmed for `amd64` and `aarch64` at `ghcr.io/dianlight/addon-sambanas[2]`.
- Per-arch intermediate images present at `ghcr.io/dianlight/{arch}-addon-sambanas[2]`.
- Cosign signature verification passes on GHCR manifest images.
- CHANGELOG Breaking Change and Migration Notes written.
- Rollback path documented and tested.

## WP6 - Upstream Reintegration and Merge (Final WP)
Status: Not started

MCP and permissions needed:
- MCP: PR MCP, GitHub Actions MCP, branch management MCP.
- CLI alternative: `gh` for branch, PR, and workflow checks.
- Permission:
  - upstream branch push rights for migration branch
  - upstream PR creation/update rights
  - CODEOWNERS/security approvals where required
  - protected-branch merge authorization

Files:
- upstream migration PR branch (aggregated from validated fork commits)

Tasks:
- [ ] Replay validated fork commits into upstream branch (`migration/buildkit-final`) using cherry-pick or equivalent.
- [ ] Remove fork-only settings before PR creation:
  - temporary publish namespaces
  - temporary canary-only overrides
  - any fork-specific secrets/registry references
- [ ] Open one upstream PR containing the full migration.
- [ ] Re-run minimum required upstream validations:
  - PR build workflow for both addons
  - selected devrelease/canary validation gate
  - label/tag parity checks
- [ ] Merge after validation pass and rollback checklist confirmation.

Reintegration rules:
- Keep commit history readable and scoped to migration WPs.
- Do not merge fork-specific secrets, registry paths, or temporary canary tag settings.
- Ensure final upstream PR contains only repository-relevant changes.

Exit criteria:
- Upstream PR created from replayed validated commits.
- Upstream validation gates pass without fork-only configuration.
- Migration merged with rollback notes preserved.

## Automation Capability Check Against WPs (Autonomous vs Manual)

**Note: No GitHub MCP is active. All `Autonomous` GitHub operations use `gh` CLI.**

Legend:
- `Autonomous`: can be executed end-to-end by agent with `gh` CLI and local tools.
- `Manual`: requires human approval, credentials, policy decision, or UI-only action.
- `Hybrid`: agent can do technical steps, human must provide/approve selected inputs.

### WP0 - Baseline and decisions
- Decision confirmation and policy lock: `Manual`
- Plan maintenance/document updates: `Autonomous`

### WP0.5 - Temporary fork rehearsal
- Create fork repository: `Autonomous` via `gh repo fork ...`
- Create rehearsal branches: `Autonomous` via `git push` / `gh`
- Sync from upstream and prepare rehearsal commits: `Autonomous`
- Configure fork secrets/tokens in GitHub settings: `Manual` (no secrets-management API available without MCP)
- Configure non-production registry namespace values and workflow vars: `Hybrid` (agent edits files, human provides allowed targets/tokens)
- Run workflow rehearsals and inspect results: `Autonomous` via `gh run list|view|rerun`
- Approve go/no-go after evidence review: `Manual`

### WP1 - CI BuildKit migration scaffold
- Edit workflow YAMLs (replace builder call with HA composite actions, inject arch extraction step): `Autonomous`
- Create/update branches and commits: `Autonomous`
- Trigger workflow runs and inspect failures: `Autonomous` via `gh run list|view|rerun`
- Validate signing policy parity (organizational/security sign-off): `Manual`
- `id-token: write` + `packages: write` permission addition: `Autonomous` (file edit)
- CAS_API_KEY removal from secrets: `Manual` (GitHub repo settings)

### WP2 - Dockerfile parity and metadata ownership
- Dockerfile updates, ARG defaults, `CLI_VERSION` → `HA_CLI_VERSION` rename: `Autonomous`
- Local static checks/lint execution: `Autonomous`
- Final acceptance of label/signing semantics: `Manual`

### WP3 - Config and local tooling migration
- Update `config.yaml`, `build.sh`, local test scripts, docs: `Autonomous`
- Execute local smoke build/run commands: `Autonomous` (requires docker buildx and QEMU locally)
- Host-specific runtime validation on real HA target (if required): `Manual/Hybrid`

### WP4 - Dependency cleanup
- Refactor `update_srat_changelog.sh`: `Autonomous`
- Update `.github/renovate.json` (add Dockerfile to SRAT manager): `Autonomous`
- Remove `build.yaml` files after gates pass: `Autonomous`
- Final cleanup approval gate: `Manual`

### WP5 - Validation, rollout, rollback readiness
- PR and branch validation runs: `Autonomous` via `gh run list|view`
- Label/manifest parity check (`docker buildx imagetools inspect`, `docker inspect`): `Autonomous`
- Cosign verification (`cosign verify`): `Autonomous`
- Production publish authorization: `Manual`
- Rollback decision if anomaly is found: `Manual`

### WP6 - Upstream reintegration and merge
- Replay validated commits to upstream branch via cherry-pick: `Autonomous`
- Open/update upstream PR: `Autonomous` via `gh pr create|edit|list`
- CI verification and status inspection: `Autonomous` via `gh run list|view`
- Required code-owner/security approvals and final merge: `Manual`

## Low-Risk Test Strategy (No-Risk-First)

### Phase 1: Zero-publish verification (safe)
- Run local lint/sanity only:
  - workflow syntax check
  - shell script lint/`bash -n`
  - Dockerfile lint (`hadolint`)
- Build locally with `docker buildx build --load` for each addon/arch one at a time.
- Do not push images.

### Phase 2: CI dry-run branch (safe)
- Use dedicated migration branch.
- Trigger workflows with publish disabled or redirected to temporary tags.
- For beta repository automation simulation, create/update draft PRs only.
- Validate:
  - computed versions
  - labels present
  - build args resolved correctly
  - no `latest` tagging side effects

### Phase 3: Canary publish (controlled risk)
- Publish one addon first (`sambanas2` recommended) to canary tag namespace:
  - example: `migration-canary-<run_number>`
- Run addon smoke install/start in HA test instance.
- Validate healthcheck, logs, and critical services.

### Phase 4: Full publish enablement
- Enable normal publish semantics after canary success.
- Run both workflows (`devrelease`, `PR`) and compare outputs with previous release behavior.

### Phase 5: Post-migration safeguards
- Keep rollback-ready branch with legacy workflow for one release window.
- Keep explicit checklist before deleting `build.yaml`:
  - Dockerfile arg parity verified
  - CI labels parity verified
  - changelog script migrated
  - Renovate tracking migrated

## Risk Register and Mitigations
- Risk: Label regressions due to missing metadata.
  - Mitigation: `build-image` auto-generates most labels. Manual input required only for `io.hass.name`, `io.hass.description`, `io.hass.type` (via `labels` input) and `BUILD_FROM` (via `build-args`). Verify all non-empty in WP5 validation gate using `docker inspect | jq`.
- Risk: Silent publish differences (tags, latest, release flags).
  - Mitigation: enforce canary tags first and compare manifest/tag outputs via `docker buildx imagetools inspect`.
- Risk: `sambanas2` script break after `build.yaml` removal.
  - Mitigation: migrate `update_srat_changelog.sh` source first, then delete files.
- Risk: dependency automation drift after removing `build.yaml`.
  - Mitigation: migrate Renovate regex managers to Dockerfile ARGs before cleanup. SRAT manager requires explicit addition of `//Dockerfile$/`.
- Risk: local script/operator confusion.
  - Mitigation: update docs and provide copy/paste smoke-test commands.
- Risk: **BUILD_ARCH runtime breakage** (MITIGATED by HA composite actions) — `build-image` action injects `BUILD_ARCH` using HA arch names (`amd64`/`aarch64`), not Docker's `TARGETARCH` (`amd64`/`arm64`). This concern applies ONLY if `docker/build-push-action` is used instead of `build-image`. With `build-image`, no manual mapping is needed.
  - Mitigation: use `home-assistant/builder/actions/build-image`. If `docker/build-push-action` is used as fallback, inject `--build-arg BUILD_ARCH=aarch64` explicitly per platform.
- Risk: **Cosign signing fails on PR workflow** — missing `id-token: write` permission.
  - Mitigation: add permission in WP1 before any rehearsal run that attempts signing.
- Risk: **Image rename breaks existing HA installations** — users tracking `dianlight/{arch}-addon-sambanas` will lose the addon after rename.
  - Mitigation: CHANGELOG Breaking Change + Migration Notes (re-add addon). Consider whether to publish transitional alias tags for one release window.
- Risk: **Renovate silent drift on SRAT version** after `build.yaml` removal.
  - Mitigation: update `managerFilePatterns` in the same PR that adds Dockerfile ARG defaults, verified green before `build.yaml` is deleted.
- Risk: **`sambanas2/test/buildLocal.sh` produces broken image** even before migration starts (5 errors).
  - Mitigation: fix in WP3 as the first task in that work package; do not treat as minor misalignment.
- Risk: **Double breaking change for existing users** — registry changes from `docker.io/dianlight/...` to `ghcr.io/dianlight/...` AND image is renamed from arch-prefixed to generic (decisions #7 + #9). Users must re-add the addon.
  - Mitigation: single CHANGELOG Breaking Change entry covering both changes together. Migration Notes with exact steps to re-add.
- Risk: **Missing registry authentication** — `build-image` requires explicit `container-registry-password`; if omitted the push fails. With GHCR the token must be `GITHUB_TOKEN` with `packages: write` permission — a `contents: read`-only token silently succeeds at login but fails at push.
  - Mitigation: always declare `packages: write` on jobs that push. Pass `container-registry-password: ${{ secrets.GITHUB_TOKEN }}`. Verify in fork rehearsal before upstream.
- Risk: **Per-arch intermediate images stay in GHCR** — `build-image` pushes `ghcr.io/dianlight/{arch}-addon-sambanas2:{tag}` as intermediate artifacts. These are not the user-facing image but they do consume registry space.
  - Mitigation: acceptable for now; can add lifecycle policy later. Document in WP5 notes.
- Risk: **`mergerelease` force-push commits wrong files** after BuildKit migration — if the new build step modifies any files not previously committed, they get accidentally included in the mergerelease commit.
  - Mitigation: verify the set of modified files between the version-mutation step and the mergerelease step is identical before and after migration. Use `git status` in CI to confirm.

## Full Fork Strategy (Recommendation)

Question: should we do a full fork of the repository for migration rehearsal?

Answer: yes, as a temporary rehearsal environment, not as the final long-term source.

Recommended model:
1. Create fork `dianlight/hassio-addons-buildkit-migration` (or similarly named temporary fork).
2. Mirror secrets needed for CI in fork (minimum required scope, no extra tokens).
3. Run full migration implementation and CI validation in fork first.
4. Validate publish steps against temporary tag namespace/registry destination.
5. After successful fork rehearsal, replay the exact commits to upstream single migration PR.

Pros of full fork rehearsal:
- Safest way to test workflow/signing/publish behavior without impacting upstream automation.
- Allows destructive experimentation (workflow refactors) with zero risk to production repo.
- Easier to iterate quickly on branch/permission/secrets issues.

Cons:
- Requires duplicate secrets and CI setup.
- Slight maintenance overhead to keep fork synced during migration window.

When to skip full fork:
- If secure secret duplication is not possible and temporary canary tags in upstream are acceptable.

## Tracking Checklist
- [x] WP0 approved (2026-04-24)
- [x] WP0.5 complete (2026-04-24)
- [x] WP1 complete (2026-04-24)
- [ ] WP2 complete
- [ ] WP3 complete
- [ ] WP4 complete
- [ ] WP5 complete
- [ ] WP6 complete

## Suggested Execution Order
1. WP0.5 temporary fork setup + rehearsal baseline
2. WP1 CI migration scaffold (BuildKit wiring first, behavior unchanged)
3. WP2 Dockerfile parity
4. WP3 config/local tooling updates
5. WP4 dependency cleanup (`build.yaml` removal last)
6. WP5 validation + canary + rollback readiness
7. WP6 upstream reintegration PR + final merge

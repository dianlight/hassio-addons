# Builder Migration Plan (Docker BuildKit)

## Goal
Migrate this repository from the retired Home Assistant legacy builder flow to the new Docker BuildKit based flow described in the Home Assistant developer blog (2026-04-02), with a complete file-by-file implementation and low-risk validation strategy.

This document remains a planning artifact (no implementation in this phase).

## Inputs Used
- Home Assistant blog post: Migrating app builds to Docker BuildKit (2026-04-02)
- Existing repository workflows and scripts
- Current repository state on branch `devrelease/sambanas2`

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

Planned MCP tool groups used in this migration:
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

Additional automation path (non-MCP):
- GitHub CLI via terminal automation (`gh`) can be used for GitHub operations when MCP is unavailable or limited.
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
- `sambanas2/config.yaml` image field is commented out.

## Target State (Migration End State)
- No usage of retired `home-assistant/builder` action or `*-builder` container image.
- Dockerfile (plus CI workflow inputs) is the only source for build args that were in `build.yaml`.
- Build/publish uses BuildKit path (new Home Assistant builder composite actions or equivalent direct `docker/buildx`).
- Addon config `image` follows generic multi-arch naming policy.
- Local build/test uses `docker buildx` or equivalent standard Docker build flow.

## File-By-File Migration Matrix (Every Touched File)

### A) CI workflows (required)
1. `.github/workflows/docker-image-dev.yml`
- Why touched: remove legacy `home-assistant/builder@master` publish path.
- Planned change:
  - Replace legacy builder step with BuildKit workflow steps/actions.
  - Keep existing branch/version/name mutation logic unchanged.
  - Map target platforms explicitly to `linux/amd64,linux/arm64`.
  - Preserve current dev tag semantics (`<base>-dev.<run_number>`).
  - Preserve signing/cosign behavior (or explicitly disable with rationale if unsupported).
  - Ensure OCI/io.hass label values are passed explicitly if no longer inferred.

2. `.github/workflows/docker-image-pr.yaml`
- Why touched: remove legacy builder for PR validation builds.
- Planned change:
  - Replace legacy builder build call with BuildKit-based non-release build.
  - Keep changelog/version consistency gate unchanged.
  - Ensure PR build does not publish latest tags by accident.
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
- Why touched: image naming migration.
- Planned change:
  - Change from arch-prefixed image template to generic multi-arch naming per locked decision.

7. `sambanas2/config.yaml`
- Why touched: image naming migration and consistency with workflow automation.
- Planned change:
  - Enable and set generic multi-arch `image` value (currently commented).

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
Status: Not started

MCP and permissions needed:
- MCP: none required for decision capture.
- Permission: maintainer-level decision authority for scope/policy lock.

Locked decisions:
1. Migrate both addons (`sambanas`, `sambanas2`).
2. Do not preserve armv7 publish support for `sambanas` in CI target workflow.
3. Use generic multi-arch image naming in `config.yaml`.
4. Execute migration in one PR.

## WP0.5 - Temporary Fork Rehearsal
Status: Not started

MCP and permissions needed:
- MCP: repository creation/branch MCP, PR MCP, GitHub Actions MCP.
- CLI alternative: `gh` for fork/PR/workflow operations.
- Permission:
  - token with `repo` + `workflow` scopes
  - write access to fork repo
  - workflow run permissions in fork
  - manual GitHub secrets setup in fork
  - non-production registry push credentials

Goal:
- Create a temporary fork for low-risk migration rehearsal and complete all migration implementation/testing there before upstream reintegration.

Repository/branch model:
- Upstream (source of truth): `dianlight/hassio-addons`
- Temporary fork (rehearsal): `dianlight/hassio-addons-buildkit-migration` (name can vary)
- Rehearsal branch in fork: `migration/buildkit-rehearsal`
- Final upstream integration branch: `migration/buildkit-final`

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

Pre-flight authorization checklist (before first rehearsal run):
- [ ] GitHub token for automation is available with required scopes (`repo`, `workflow`, PR write).
- [ ] Permission confirmed to trigger, rerun, and cancel workflows in fork and upstream.
- [ ] Fork repository created and writable by migration maintainers.
- [ ] Required registry credentials are available for non-production namespace.
- [ ] Fork GitHub secrets created manually and validated (minimum secret set only).
- [ ] GitHub CLI is installed and authenticated (`gh auth status` is healthy).
- [ ] Branch protection policy understood for upstream target branches.
- [ ] Required manual approvers identified (CODEOWNERS/security/release).
- [ ] Temporary publish namespace approved for canary rehearsal tags.
- [ ] Beta-repo rehearsal policy confirmed: automation creates draft PRs only.
- [ ] MCP access confirmed for:
  - repository and branch operations
  - pull request operations
  - GitHub Actions run inspection
- [ ] Rollback owner assigned and rollback communication channel confirmed.

GitHub CLI runbook (copy-paste, WP0.5 rehearsal):
```bash
# 0) Inputs
ORIGINAL_REPO="https://github.com/dianlight/hassio-addons"
FORK_NAME="hassio-addons-buildkit-migration"
REHEARSAL_BRANCH="migration/buildkit-rehearsal"
UPSTREAM_REMOTE_NAME="upstream"

# 1) Verify gh authentication and scopes
gh auth status

# 2) Fork and clone (if repo folder is not already present)
gh repo fork "$ORIGINAL_REPO" --fork-name "$FORK_NAME" --clone
cd "$FORK_NAME"

# 3) Ensure upstream remote exists and sync from upstream master
git remote add "$UPSTREAM_REMOTE_NAME" "$ORIGINAL_REPO" 2>/dev/null || true
git fetch "$UPSTREAM_REMOTE_NAME" --prune
git checkout -B "$REHEARSAL_BRANCH" "$UPSTREAM_REMOTE_NAME/master"
git push -u origin "$REHEARSAL_BRANCH"

# 4) After applying migration edits, commit and push rehearsal branch
git add .
git commit -m "chore(buildkit): rehearsal migration changes" || true
git push origin "$REHEARSAL_BRANCH"

# 5) Validate workflow execution (list and inspect)
gh run list --limit 20
gh run view --log

# 6) Beta-repo simulation rule: PRs must be draft-only during rehearsal
# (Use --draft when creating PRs in beta repo automation paths.)
gh pr create --draft --title "[rehearsal] BuildKit migration" --body "WP0.5 rehearsal" || true

# 7) Verify PR draft state
gh pr view --json isDraft,title,headRefName,baseRefName
```

Exit criteria:
- Rehearsal start gate: all pre-flight authorization checklist items are completed.
- Fork rehearsal complete and green.
- Validation evidence bundle is complete and approved for upstream reintegration.

## WP1 - CI BuildKit Migration Scaffold
Status: Not started

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

Tasks:
- [ ] Replace legacy builder action calls with BuildKit-based implementation.
- [ ] Keep all existing version/name mutation steps untouched first.
- [ ] Implement explicit platform matrix (`amd64`, `aarch64`).
- [ ] Ensure no unintended publish on PR workflow.
- [ ] Ensure prerelease beta-repo PR creation remains draft-only during rehearsal (for safe behavior simulation).
- [ ] Preserve or explicitly re-implement signing behavior.
- [ ] Pass required metadata labels explicitly.

Exit criteria:
- No references to `home-assistant/builder@master`.
- CI builds complete in dry-run/non-release mode.

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
- [ ] Move `build.yaml` values into Dockerfile defaults where appropriate.
- [ ] Define explicit CI-provided metadata args for labels.
- [ ] Verify both Dockerfiles can build via BuildKit without `build.yaml` dependency.

Exit criteria:
- Dockerfiles contain/receive all required values for successful build and labeling.

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
- [ ] Update image naming to generic multi-arch values.
- [ ] Replace legacy local builder container usage with `docker buildx`.
- [ ] Correct `sambanas2` test script path/tag mismatches.
- [ ] Add non-push smoke test mode to local tooling.

Exit criteria:
- Local scripts build and run both addons without legacy builder images.

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
- [ ] Migrate SRAT version source from `build.yaml` to Dockerfile.
- [ ] Update Renovate to keep dependency/version updates working after `build.yaml` removal.
- [ ] Remove both `build.yaml` files after successful validation gates.

Exit criteria:
- No runtime or automation dependency on `build.yaml` remains.

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
- [ ] Add/update rollback and troubleshooting notes.

Exit criteria:
- All workflows green with BuildKit-only path.
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

## MCP Capability Check Against WPs (Autonomous vs Manual)

Legend:
- `Autonomous`: can be executed end-to-end by agent with available MCP/tooling.
- `Manual`: requires human approval, credentials, policy decision, or UI-only action.
- `Hybrid`: agent can do technical steps, human must provide/approve selected inputs.

### WP0 - Baseline and decisions
- Decision confirmation and policy lock: `Manual`
- Plan maintenance/document updates: `Autonomous`

### WP0.5 - Temporary fork rehearsal
- Create fork repository: `Autonomous` via repository-creation MCP (`fork repository`) or GitHub CLI (`gh repo fork ...`).
- Create rehearsal branches: `Autonomous` via branch MCP (`create branch`).
- Sync from upstream and prepare rehearsal commits: `Autonomous`.
- Configure fork secrets/tokens in GitHub settings: `Manual` (no secrets-management MCP exposed).
- Configure non-production registry namespace values and workflow vars: `Hybrid` (agent edits files, human provides allowed targets/tokens).
- Run workflow rehearsals and inspect results: `Autonomous` via GitHub Actions MCP (`list/get workflow runs/jobs/artifacts`) or GitHub CLI (`gh run ...`).
- Approve go/no-go after evidence review: `Manual`.

### WP1 - CI BuildKit migration scaffold
- Edit workflow YAMLs: `Autonomous`.
- Create/update branches and commits: `Autonomous`.
- Trigger workflow runs and inspect failures: `Autonomous` via GitHub Actions MCP or GitHub CLI (`gh run ...`).
- Validate signing policy parity (organizational/security sign-off): `Manual`.

### WP2 - Dockerfile parity and metadata ownership
- Dockerfile updates and metadata arg mapping: `Autonomous`.
- Local static checks/lint execution: `Autonomous`.
- Final acceptance of label/signing semantics: `Manual`.

### WP3 - Config and local tooling migration
- Update `config.yaml`, `build.sh`, local test scripts, docs: `Autonomous`.
- Execute local smoke build/run commands: `Autonomous`.
- Host-specific runtime validation on real HA target (if required): `Manual/Hybrid` depending on environment access.

### WP4 - Dependency cleanup
- Refactor `update_srat_changelog.sh`: `Autonomous`.
- Update `.github/renovate.json`: `Autonomous`.
- Remove `build.yaml` files after gates pass: `Autonomous`.
- Final cleanup approval gate: `Manual`.

### WP5 - Validation, rollout, rollback readiness
- PR and branch validation runs: `Autonomous` via GitHub Actions MCP or GitHub CLI (`gh run ...`).
- Artifact/log collection and parity report: `Autonomous`.
- Production publish authorization: `Manual`.
- Rollback decision if anomaly is found: `Manual`.

### WP6 - Upstream reintegration and merge
- Replay validated commits to upstream branch: `Autonomous`.
- Open/update upstream PR: `Autonomous` via PR MCP or GitHub CLI (`gh pr create|edit|list`).
- CI verification and status inspection: `Autonomous` via GitHub Actions MCP or GitHub CLI (`gh run ...`).
- Required code-owner/security approvals and final merge click: `Manual`.

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
- Risk: Label regressions due to missing auto-inferred metadata.
  - Mitigation: Explicitly set io.hass/OCI labels in workflow build args.
- Risk: Silent publish differences (tags, latest, release flags).
  - Mitigation: enforce canary tags first and compare manifest/tag outputs.
- Risk: `sambanas2` script break after `build.yaml` removal.
  - Mitigation: migrate `update_srat_changelog.sh` source first, then delete files.
- Risk: dependency automation drift after removing `build.yaml`.
  - Mitigation: migrate Renovate regex managers to Dockerfile ARGs before cleanup.
- Risk: local script/operator confusion.
  - Mitigation: update docs and provide copy/paste smoke-test commands.

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
- [ ] WP0 approved
- [ ] WP0.5 complete
- [ ] WP1 complete
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

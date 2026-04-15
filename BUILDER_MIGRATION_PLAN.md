# Builder Migration Plan (Docker BuildKit)

## Goal
Migrate this repository from the retired Home Assistant legacy builder flow to the new Docker BuildKit based flow described in the Home Assistant developer blog (2026-04-02), without starting implementation in this phase.

## Inputs Used
- Home Assistant blog post: Migrating app builds to Docker BuildKit (2026-04-02)
- Existing repository workflows and scripts

## Scope
- In scope:
  - sambanas
  - sambanas2
  - GitHub Actions workflows for dev/pr/release build and publish
  - Local/manual build and test scripts
  - image field conventions in addon config
- Out of scope for this plan phase:
  - Actual code/workflow edits
  - Publishing behavior changes not required by builder migration

## Current State Analysis

### 1. Manual and local build workflow (current)
- Root local build entrypoint is build.sh.
- build.sh currently runs legacy arch-specific builder containers:
  - ghcr.io/home-assistant/${arch}-builder:latest
- build.sh relies on addon metadata and architecture from config.yaml/config.json, then delegates build logic to legacy builder.
- sambanas and sambanas2 both still have build.yaml files.
- Local test scripts in sambanas/test and sambanas2/test build images via docker build with old style base image arguments such as homeassistant/armv7-base.
- sambanas2/scripts/update_srat_changelog.sh reads SRAT version from build.yaml (.args.SRAT_VERSION).

### 2. GitHub Actions workflow (current)
- .github/workflows/docker-image-dev.yml uses home-assistant/builder@master for devrelease/* builds.
- .github/workflows/docker-image-pr.yaml uses home-assistant/builder@master for release validation builds.
- .github/workflows/docker-image-pre.yml currently manages prerelease PR flow (beta/master sync) and does not invoke legacy builder directly.
- Existing workflows also modify config.yaml values (name/version/image) as part of release automation.

### 3. Dockerfile state (current)
- Dockerfiles still expect legacy builder-injected args:
  - BUILD_FROM, BUILD_ARCH, BUILD_NAME, BUILD_DESCRIPTION, BUILD_VERSION, BUILD_REPOSITORY, BUILD_REF, BUILD_DATE
- Docker labels include io.hass.* and OCI labels generated from those args.
- build.yaml currently contains build_from and args values that must be migrated into Dockerfile defaults where appropriate.

## Target State (from HA migration guidance)
- No usage of retired home-assistant/builder container/action.
- Dockerfile is single source of truth for build inputs previously stored in build.yaml.
- GitHub Actions use new home-assistant/builder composite actions (BuildKit based), or equivalent direct Docker BuildKit setup.
- config.yaml image uses generic multi-arch image name (preferred), while compatibility fallback remains possible.
- Local build/testing can use docker build / docker buildx directly.

## Migration Work Packages

## WP0 - Baseline and decision capture
Status: Completed

Tasks:
- [x] Confirm migration boundaries (sambanas only vs sambanas + sambanas2): both addons in scope now.
- [x] Confirm whether armv7 support for sambanas must be preserved in CI publish: no, armv7 publish removed in target state.
- [x] Confirm desired final image naming policy in config.yaml: generic multi-arch image naming.
- [x] Confirm if we should migrate all legacy references in one PR or phased PRs: one migration PR.

Exit criteria:
- All policy decisions approved.

## WP1 - Dockerfile and build input migration
Status: Not started

Tasks:
- [ ] For sambanas, map build.yaml keys to Dockerfile:
  - build_from -> Dockerfile FROM/default ARG strategy
  - args -> Dockerfile ARG defaults
  - labels -> ensure explicitly defined where required
- [ ] For sambanas2, move args defaults from build.yaml into Dockerfile ARG defaults (HA_CLI_VERSION, SRAT_VERSION, SAMBA_VERSION).
- [ ] Ensure Dockerfile no longer depends on externally required build.yaml values for normal CI path.
- [ ] Define replacement strategy for legacy builder metadata args if new actions do not provide equivalent values automatically.

Exit criteria:
- build.yaml data is fully represented in Dockerfiles/configured action inputs.

## WP2 - GitHub Actions migration to new builder actions
Status: Not started

Tasks:
- [ ] Replace home-assistant/builder@master in:
  - .github/workflows/docker-image-dev.yml
  - .github/workflows/docker-image-pr.yaml
- [ ] Use new BuildKit based composite actions from home-assistant/builder repo (example workflow parity).
- [ ] Preserve existing release semantics where required:
  - dev tag format logic
  - target addon selection from branch/input
  - cosign/signing behavior parity (if still required)
- [ ] Validate labels handling:
  - explicitly provide any io.hass.* labels that are no longer inferred
- [ ] Ensure authentication and package push targets remain correct (DockerHub/GHCR decisions aligned).

Exit criteria:
- CI builds and publishes using BuildKit path only; no deprecated action remains.

## WP3 - Local/manual workflow migration
Status: Not started

Tasks:
- [ ] Replace root build.sh legacy builder container usage with docker buildx based workflow.
- [ ] Update sambanas/test/buildLocal.sh and runLocal.sh to use current base/build args conventions.
- [ ] Update sambanas2/test/buildLocal.sh and runLocal.sh (currently appears copied from sambanas and mismatched).
- [ ] Document local build commands for developers.

Exit criteria:
- Local build/test does not require home-assistant/*-builder images.

## WP4 - Script and config dependency cleanup
Status: Not started

Tasks:
- [ ] Refactor sambanas2/scripts/update_srat_changelog.sh to read SRAT version from Dockerfile ARG default (or another agreed source) instead of build.yaml.
- [ ] Remove sambanas/build.yaml and sambanas2/build.yaml after parity confirmation.
- [ ] Update any workflow/script comments that still reference legacy builder behavior.

Exit criteria:
- No runtime or automation dependency on build.yaml remains.

## WP5 - Validation and rollout
Status: Not started

Tasks:
- [ ] Validate PR build workflow end-to-end for at least one addon.
- [ ] Validate devrelease publish workflow and produced tags.
- [ ] Validate prerelease flow still creates expected PRs and release branches.
- [ ] Validate images resolve correctly from config.yaml with selected naming policy.
- [ ] Run local smoke build instructions for sambanas2 and sambanas.

Exit criteria:
- All required workflows pass with BuildKit migration complete.

## Tracking Checklist
- [x] WP0 approved
- [ ] WP1 complete
- [ ] WP2 complete
- [ ] WP3 complete
- [ ] WP4 complete
- [ ] WP5 complete

## Risks and Mitigations
- Risk: Custom release/version mutation logic in workflows may not map cleanly to new actions.
  - Mitigation: Keep existing version/name mutation steps unchanged first, migrate only build invocation, then refine.
- Risk: Legacy auto-inferred labels disappear.
  - Mitigation: Explicitly define required labels via action inputs or Dockerfile LABEL.
- Risk: Image naming migration can break existing users expecting arch-prefixed images.
  - Mitigation: Use phased compatibility period and communicate deprecation timeline.
- Risk: sambanas2 helper script breaks when build.yaml is removed.
  - Mitigation: Migrate script source-of-truth before deleting build.yaml.

## Decisions Locked
1. Migrate both addons: sambanas and sambanas2.
2. Do not preserve armv7 publish support for sambanas in CI target workflow.
3. Use generic multi-arch image naming in config.yaml.
4. Execute migration in one PR.

## Suggested Execution Order
1. WP2 for non-breaking CI migration scaffold
2. WP1 Dockerfile parity completion
3. WP4 dependency cleanup
4. WP3 local tooling updates
5. WP5 validation and release

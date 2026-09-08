# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> This file mirrors the configuration in `.github/copilot-instructions.md` and `.github/instructions/` so Claude Code and GitHub Copilot can be used interchangeably. The canonical Copilot skills and prompts live under `.github/skills/` and `.github/prompts/`.

---

## Repository Structure

Monorepo of Home Assistant (Hass.io) add-ons. Each add-on is an independent Docker container with its own `Dockerfile`, `config.yaml`, `rootfs/` services, tests, and docs.

| Directory | Status |
|---|---|
| `sambanas2/` | **Active development** — all feature work goes here |
| `sambanas/` | **Maintenance mode** — critical fixes only; direct users to `sambanas2` |
| `plex/`, `RPiMySensor/` | **Deprecated/Legacy** |
| `addon-plex/` | Git submodule |

Each add-on directory contains: `Dockerfile`, `config.yaml` (or `config.json`), `build.yaml`, `rootfs/`, `test/`, `scripts/`, `translations/`, `DOCS.md`, `README.md`, `CHANGELOG.md`.

---

## Build and Validation

### Prerequisites

```bash
git submodule update --init --recursive
# Required tools: yq, jq, hadolint, docker (with privileged container support)
```

### Validate before building

```bash
# YAML addon (e.g. sambanas2)
yq -e '.name, .version, .arch, .image' sambanas2/config.yaml

# JSON addon
jq -e '.name, .version, .arch' <addon>/config.json

# Lint Dockerfile
hadolint -c sambanas2/.hadolint.yaml sambanas2/Dockerfile
```

### Local build

```bash
check=no archs=--aarch64 ./build.sh sambanas2
check=no archs=--amd64   ./build.sh sambanas2
```

**Never cancel a builder run once started.** Builds take 15–45 minutes per architecture. The Docker pull/build phases may appear stalled while still progressing. Use 60+ minute timeouts.

### Run tests

```bash
./sambanas2/test/test-binary-upgrade.sh
./sambanas2/test/test-binary-upgrade-integration.sh  # requires gcc, objdump
./sambanas2/test/test-zfs-support-output.sh
```

---

## CI/CD — Branch Naming Drives Workflows

| Branch pattern | Effect |
|---|---|
| `devrelease/<addon>` | Builds and publishes dev image tagged `-dev.<run_number>` |
| `prerelease/<addon>_<version>` | Syncs to beta repo; optionally creates draft PR to master |
| `master` | Stable/release branch |

The dev workflow auto-creates a `mergerelease/<addon>` branch for script-commit side-effects and opens a PR to `prerelease/`.

---

## Conventions

### Scoping — stay inside the target add-on directory

Never mix documentation or logic across add-ons. The `documentation-validation.yml` CI workflow **fails PRs** that:
- Change code in an addon without updating at least one `.md` file in the same addon directory
- Add cross-addon documentation references (exception: `sambanas/README.md` may reference `sambanas2`)
- Change `prerelease/**` without an `image` field in `config.yaml`

### Documentation update mapping

| What changed | Which doc to update |
|---|---|
| `config.yaml` options | `DOCS.md` |
| `Dockerfile` dependencies | `README.md` |
| `rootfs/` scripts / services | `DOCS.md` + `README.md` |
| Feature / behavior | `README.md` + `DOCS.md` + `CHANGELOG.md` |
| Bug fix / security | `CHANGELOG.md` |

### Changelog format (`.github/CHANGELOG_TEMPLATE.md`)

```markdown
## [Version] - YYYY-MM-DD

### Added
### Changed
### Fixed
### Removed
### Breaking Changes
### Migration Notes
```

Include only sections that have content. Use semantic versioning (`MAJOR.MINOR.PATCH`).

### Shell scripts (`.github/instructions/shell.instructions.md`)

- Quote all variable expansions: `"$var"`
- Prefer `[[ ... ]]` over `[ ... ]` and `$(...)` over backticks
- New scripts: `set -euo pipefail` at the top
- Existing scripts: introduce strict mode only if it won't break current flow
- Validate external tools: `command -v toolname >/dev/null`
- Emit errors to stderr before exit

---

## Skills and Prompts

These are reusable workflows available to both Claude Code and GitHub Copilot.

### `/addon-validate` (`.github/skills/addon-validate/SKILL.md`)

Run after changing `config.yaml`, `Dockerfile`, `rootfs/`, or `build.yaml`:
1. `git submodule update --init --recursive`
2. Validate config (`yq` or `jq`)
3. `hadolint -c <addon>/.hadolint.yaml <addon>/Dockerfile`
4. `check=no archs=--aarch64 ./build.sh <addon>`

### Release notes prompt (`.github/prompts/release-notes.prompt.md`)

Generates a changelog entry + PR summary scoped to one add-on, following `CHANGELOG_TEMPLATE.md`. Suggests a version bump with rationale and lists documentation files that need updating.

---

## Pending: BuildKit Migration

`BUILDER_MIGRATION_PLAN.md` documents a complete plan (WP0–WP6, all not started) to migrate from the legacy `home-assistant/builder` action to Docker BuildKit. Key future impacts:
- `build.sh` → `docker buildx build`
- `build.yaml` files will be removed; version ARGs move into Dockerfiles
- `renovate.json` regex managers must be updated from `build.yaml` to Dockerfile
- `sambanas2/scripts/update_srat_changelog.sh` source-of-truth moves to Dockerfile

Recommended order: WP0.5 (fork rehearsal on `hassio-addons-buildkit-migration`) → WP1 → WP2 → WP3 → WP4 → WP5 → WP6.

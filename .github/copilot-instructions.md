# Project Guidelines

Use this file as the primary workspace bootstrap for AI agents in this repository.

## Code Style

- Keep changes scoped to the target add-on directory.
- Prefer minimal edits and preserve existing shell/YAML conventions in each add-on.
- Update documentation alongside code changes. See [.copilot-instructions.md](../.copilot-instructions.md) for documentation update policy.

## Architecture

- Monorepo with multiple mostly independent Home Assistant add-ons:
  - `sambanas/`: original Samba NAS (maintenance mode).
  - `sambanas2/`: next-generation Samba NAS (active development).
  - `RPiMySensor/` and `plex/`: legacy/deprecated add-ons.
  - `addon-plex/`: separate submodule repository.
- Root build entrypoint is [build.sh](../build.sh).
- Add-on configs use either `config.yaml` or `config.json`; detect format before validation/build actions.

## Build And Test

Run these checks before or with build-related changes:

1. Initialize submodules:
   - `git submodule update --init --recursive`
2. Validate add-on config:
   - YAML: `yq -e '.name, .version, .arch, .image' <addon>/config.yaml`
   - JSON: `jq -e '.name, .version, .arch' <addon>/config.json`
3. Lint Dockerfile:
   - `hadolint -c <addon>/.hadolint.yaml <addon>/Dockerfile`
4. Build locally (example):
   - `check=no archs=--aarch64 ./build.sh <addon>`

Critical build behavior:

- Never cancel Home Assistant builder runs once started.
- Builds can take 15-45 minutes per architecture; use 60+ minute timeouts.
- Docker pulls/builds may look stalled while still progressing.

See [README.md](../README.md) and add-on docs for user-facing setup and feature details.

## Conventions

- Respect add-on lifecycle status:
  - `sambanas` accepts only critical fixes.
  - `sambanas2` is the active feature path.
  - `RPiMySensor` and `plex` are deprecated.
- Do not mix project-specific user documentation across add-ons.
- When changing add-on behavior, update the local documentation set in that add-on:
  - `README.md`
  - `DOCS.md`
  - `CHANGELOG.md`

Reference docs instead of duplicating guidance:

- Repository overview: [README.md](../README.md)
- SambaNAS docs: [sambanas/DOCS.md](../sambanas/DOCS.md)
- SambaNAS2 docs: [sambanas2/DOCS.md](../sambanas2/DOCS.md)
- SambaNAS2 tests: [sambanas2/test/README.md](../sambanas2/test/README.md)
- Changelog format: [.github/CHANGELOG_TEMPLATE.md](CHANGELOG_TEMPLATE.md)
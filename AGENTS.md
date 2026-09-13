# Hassio Addons — Home Assistant Add-on Repository

This file is the primary workspace bootstrap for AI agents working in this repository. Scoped rules for individual add-ons live in nested `AGENTS.md` files (e.g. `sambanas2/AGENTS.md`) and apply when working inside those directories.

## Repository Structure

Monorepo of Home Assistant (Hass.io) add-ons. Each top-level directory represents a separate, self-contained project:

- `sambanas/` — original Samba NAS add-on (maintenance mode)
- `sambanas2/` — next-generation Samba NAS add-on (active development)
- `plex/`, `RPiMySensor/` — deprecated/legacy add-ons
- `addon-plex/` — separate git submodule

Root build entrypoint is `build.sh`. Add-on configs use either `config.yaml` or `config.json`; detect the format before running validation or build actions.

## Code Style

- Keep changes scoped to the target add-on directory.
- Prefer minimal edits and preserve existing shell/YAML conventions in each add-on.
- Update documentation alongside code changes. See [Documentation Update Rules](#documentation-update-rules).

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
- Builds can take 15–45 minutes per architecture; use 60+ minute timeouts.
- Docker pulls/builds may look stalled while still progressing.

Reference docs instead of duplicating guidance:

- Repository overview: `README.md`
- SambaNAS docs: `sambanas/DOCS.md`
- SambaNAS2 docs: `sambanas2/DOCS.md`
- SambaNAS2 tests: `sambanas2/test/README.md`
- Changelog format: `.github/CHANGELOG_TEMPLATE.md`

## Documentation Update Rules

### Before Validating ANY Change

1. **Always update relevant `*.md` files** in the affected add-on directory
2. **Never cross-reference information** between different projects
3. **Maintain project isolation** — each project's documentation should be self-contained

### Markdown Files to Update Per Project

Each add-on typically contains:

- `README.md` — main project documentation, installation instructions, features
- `DOCS.md` — detailed configuration and usage documentation
- `CHANGELOG.md` — version history and changes

### Add-On-Specific Documentation Guidelines

#### For `sambanas/` (Maintenance Mode)
- Always include maintenance mode notice in README.md
- Direct users to `sambanas2` for new features
- Only document critical bug fixes in CHANGELOG.md
- Keep documentation frozen except for security/critical updates

#### For `sambanas2/` (Active Development)
- Update README.md with new features and capabilities
- Ensure DOCS.md reflects current configuration options
- Update CHANGELOG.md for all changes
- Include migration notes from sambanas if relevant
- Update installation badges and statistics

#### For `plex/` and `addon-plex/`
- Keep these projects completely separate
- Document unique features of each implementation
- Update version compatibility information
- Include Plex-specific configuration examples

#### For `RPiMySensor/`
- Focus on Raspberry Pi specific documentation
- Include hardware compatibility information
- Document sensor configuration examples

### Mandatory Pre-Validation Checklist

Before any code change validation:

1. ✅ Identify which add-on(s) are affected by the change
2. ✅ Update README.md if:
   - New features are added
   - Installation instructions change
   - System requirements change
   - Project status changes
3. ✅ Update DOCS.md if:
   - Configuration options are added/modified
   - Usage instructions change
   - New examples are needed
4. ✅ Update CHANGELOG.md with:
   - Version number (if release)
   - Date of change
   - Clear description of changes
   - Breaking changes highlighted
   - Migration instructions if needed
5. ✅ Verify no cross-project references are introduced
6. ✅ Check that URLs and badges point to correct project paths
7. ✅ Ensure documentation language is consistent within project
8. ✅ Validate that examples and code snippets are current

### Documentation Style Guidelines

- Use clear, concise language
- Include code examples where applicable
- Maintain consistent formatting within each project
- Use proper markdown syntax
- Include relevant badges and shields for each project
- Keep installation instructions up-to-date
- Document all configuration options thoroughly

### Change Detection Rules

When making changes to:

- **Configuration files** (`config.json`, `config.yaml`) → Update DOCS.md
- **Dockerfiles** → Update README.md (if dependencies change)
- **Scripts in rootfs/** → Update DOCS.md and README.md
- **Service definitions** → Update DOCS.md with service changes
- **Dependencies or requirements** → Update README.md
- **Features or functionality** → Update README.md, DOCS.md, and CHANGELOG.md

### Error Prevention

- Never copy documentation between projects
- Don't reference features from other projects
- Avoid generic documentation that doesn't match the specific project
- Don't use absolute paths that break project isolation
- Ensure all links and references are project-specific

### Validation Requirements

Before submitting any PR:

1. All affected `*.md` files must be updated
2. Documentation must be tested for accuracy
3. Links and references must be validated
4. Examples must be current and working
5. Version information must be consistent across files

Remember: Documentation is code. Treat it with the same rigor as source code changes.

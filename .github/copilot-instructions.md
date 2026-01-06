# Home Assistant Add-ons Repository (hassio-addons)

Home Assistant add-ons repository containing Docker-based add-ons for Home Assistant. This repository includes multiple add-ons: SambaNAS, RPiMySensor, and Plex Media Server, with a Docker-based build system using Home Assistant's official builder.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Repository Setup and Prerequisites
- Clone repository: `git clone https://github.com/dianlight/hassio-addons.git`
- Initialize submodules: `git submodule update --init --recursive` -- takes 1-2 seconds
- Ensure Docker is running: `docker --version && docker info`
- Install required tools:
  - `curl -L https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 -o /usr/local/bin/hadolint && chmod +x /usr/local/bin/hadolint`
  - `yq` and `jq` should already be available on most systems

### Build System
- **CRITICAL**: Full addon builds take 15-45 minutes per architecture. NEVER CANCEL builds. Set timeout to 60+ minutes minimum.
- Local build command: `check=no archs=--aarch64 ./build.sh <addon_name>` 
- Architecture detection: Script automatically detects amd64/aarch64, handles Apple M1 properly
- Build images are pulled from `ghcr.io/home-assistant/{arch}-builder:latest` -- takes 2-5 minutes on first run
- **NEVER CANCEL**: Docker image pulls and builds can appear to hang but are actually downloading/building. Wait at least 60 minutes.

### Development Workflow
1. **Setup**: `git submodule update --init --recursive` (1-2 seconds)
2. **Validate addon configs**: 
   - YAML configs: `yq -e '.name, .version, .arch, .image' <addon>/config.yaml`
   - JSON configs: `jq -e '.name, .version, .arch' <addon>/config.json`
3. **Lint Dockerfiles**: `hadolint -c <addon>/.hadolint.yaml <addon>/Dockerfile` -- takes <1 second
4. **Test build preparation**: Use build.sh with `check=no` to validate without pushing to registry
5. **NEVER CANCEL**: Any build command that starts the Home Assistant builder - builds take 15-45 minutes

### Repository Structure
- `sambanas/` - Samba NAS addon (YAML config, maintenance mode)
- `RPiMySensor/` - Raspberry Pi MySensor Gateway (JSON config, deprecated)  
- `plex/` - Plex Media Server (JSON config, deprecated)
- `addon-plex/` - Plex addon submodule (separate repository)
- `build.sh` - Main build script for local development
- `repository.json` - Repository metadata for Home Assistant
- `.github/workflows/` - CI/CD pipelines for automated builds

## Validation

- **Always run hadolint before builds**: `hadolint -c <addon>/.hadolint.yaml <addon>/Dockerfile`
- **Always validate configs**: Use `yq`/`jq` to parse YAML/JSON configs before building
- **Test architecture detection**: Build script handles x86_64->amd64, arm64->aarch64 conversion properly
- **Manual validation scenarios**: 
  - For SambaNAS: Verify config parsing, Dockerfile linting, architecture list generation
  - For RPiMySensor: Verify JSON config structure, deprecated status handling
  - For Plex: Verify JSON config structure, deprecated status understanding
- **NEVER CANCEL builds or tests** - always wait for completion, even if it takes 45+ minutes

## Common Tasks

The following are outputs from frequently run commands. Reference them instead of viewing, searching, or running bash commands to save time.

### Repository Root Structure
```
.
├── .devcontainer/          # VS Code development container config
├── .github/               # GitHub Actions workflows and templates
├── .vscode/               # VS Code workspace settings  
├── RPiMySensor/           # Raspberry Pi MySensor Gateway addon
├── addon-plex/            # Plex addon (git submodule)
├── plex/                  # Legacy Plex addon (deprecated)
├── sambanas/              # Samba NAS addon (maintenance mode)
├── build.sh*              # Main build script
├── repository.json        # Repository metadata
└── README.md             # Repository documentation
```

### Add-on Directory Structure (Example: sambanas)
```
sambanas/
├── .hadolint.yaml        # Hadolint configuration
├── build.yaml           # Build configuration
├── config.yaml          # Add-on configuration
├── Dockerfile           # Container definition
├── README.md            # Add-on documentation
├── DOCS.md              # Detailed documentation
├── CHANGELOG.md         # Version history
├── rootfs/              # Container root filesystem
├── test/                # Test configurations
└── translations/        # Internationalization
```

### Supported Architectures by Add-on
- **sambanas**: armv7, aarch64, amd64
- **RPiMySensor**: armhf, armv7 (Raspberry Pi specific)
- **plex**: aarch64, amd64, armv7, i386

### Build Script Usage Examples
- Build single architecture: `check=no archs=--aarch64 ./build.sh sambanas`
- Build all architectures: `check=no ./build.sh sambanas` 
- Dry run validation: `check=no archs=--aarch64 timeout 10s ./build.sh sambanas`

### Configuration File Examples

#### YAML Config (sambanas/config.yaml)
```yaml
name: Samba NAS
version: 12.5.0-nas  
slug: sambanas
arch:
  - armv7
  - aarch64  
  - amd64
image: dianlight/{arch}-addon-sambanas
```

#### JSON Config (RPiMySensor/config.json)
```json
{
  "name": "RPi MySensor Gateway",
  "version": "0.0.25", 
  "slug": "rpi-mysensor-gw",
  "arch": ["armhf", "armv7"],
  "image": "dianlight/rpi-mysensor-gw-{arch}"
}
```

### GitHub Actions Workflows
- `docker-image-pr.yaml` - Build on pull requests to master
- `docker-image-dev.yml` - Build on devrelease/* branches
- `docker-image-pre.yml` - Build on prerelease/* branches  
- `block-pr-if-image-is-not-set.yml` - Validate addon has image configured
- Build times in CI: 15-30 minutes per architecture, multiple architectures built in parallel

### Development Container
- Uses `ghcr.io/home-assistant/devcontainer:2-addons` image
- Includes Home Assistant development tools and VS Code extensions
- Bootstrap command: `bash devcontainer_bootstrap` (referenced but file may not exist)
- Ports: 7123:8123 (Home Assistant), 7357:4357 (development)

## Critical Reminders

- **NEVER CANCEL ANY BUILD COMMAND** - Builds may take 15-45 minutes per architecture
- **Set explicit timeouts of 60+ minutes** for any build commands using `timeout` parameter  
- **Docker operations can appear to hang** - This is normal for large image downloads/builds
- **Always validate configs before building** - Use yq/jq to check syntax
- **Hadolint must pass** before attempting builds - Fix all linting issues first
- **Submodule initialization required** - Run `git submodule update --init --recursive` after clone
- **Architecture detection is automatic** - Build script handles platform differences
- **Multiple add-ons are deprecated** - Check status before making changes (plex, RPiMySensor)
- **SambaNAS is in maintenance mode** - Only critical bug fixes, no new features
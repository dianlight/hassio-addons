# Home Assistant Add-ons Repository

**CRITICAL**: Always follow these instructions completely. Only fallback to additional search and context gathering if the information in these instructions is incomplete or found to be in error.

This repository contains Home Assistant add-ons including sambanas (Samba NAS), RPiMySensor (MySensor Gateway), and plex (deprecated). Each add-on is built as a Docker container using the Home Assistant builder system.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap and Setup
- Install required tools:
  - `wget -qO /tmp/hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64 && chmod +x /tmp/hadolint && sudo mv /tmp/hadolint /usr/local/bin/hadolint`
  - Docker, yq, and jq are pre-installed in most environments

### Build System
- **NEVER CANCEL** builds - they require 2-5 minutes minimum and may take up to 30+ minutes for full cross-architecture builds
- Use `./build.sh <addon-name>` to build add-ons locally
- For local builds without publishing: `check=no archs=--amd64 ./build.sh sambanas`
- For testing configs only: `check=yes ./build.sh sambanas`
- **CRITICAL**: Set timeout to 60+ minutes for all build commands. Builds WILL take significant time.

### Linting
- Always lint Dockerfiles before building: `hadolint -c <addon>/.hadolint.yaml <addon>/Dockerfile`
- Hadolint takes ~1 second and should always pass before attempting builds

### Local Development and Testing
- Each addon has a `test/` directory with local testing scripts:
  - `test/buildLocal.sh` - Build addon locally for testing
  - `test/runLocal.sh` - Run addon locally with test configuration
  - `test/options.json` - Test configuration options
- **WARNING**: Full Home Assistant builder builds require specific environment variables and may fail in sandboxed environments
- Use the devcontainer setup for full development environment: `.devcontainer/devcontainer.json`

## Repository Structure

### Key Directories
- `sambanas/` - Samba NAS addon (active, maintenance mode)
- `RPiMySensor/` - Raspberry Pi MySensor Gateway (deprecated)
- `plex/` - Plex Media Server addon (deprecated)
- `addon-plex/` - Empty directory (legacy)
- `.github/workflows/` - CI/CD automation

### Configuration Files
- Each addon has `config.yaml` or `config.json` defining metadata, options, and schema
- `build.yaml` defines build arguments and base images
- `Dockerfile` contains the container build instructions
- `.hadolint.yaml` configures Dockerfile linting rules

## Build Process and Timing

### Expected Build Times (NEVER CANCEL)
- **Dockerfile linting**: ~1 second
- **Local Docker build**: 2-5 minutes (often fails in sandboxed environments)
- **Full Home Assistant builder**: 5-30+ minutes depending on addon complexity
- **Cross-architecture builds**: 15-45+ minutes

### Build Commands
- Test config: `check=yes ./build.sh <addon-name>`
- Local build: `check=no archs=--amd64 ./build.sh <addon-name>`
- Specific architecture: `check=no archs=--aarch64 ./build.sh <addon-name>`
- **CRITICAL**: Always set timeouts to 60+ minutes minimum

### Common Build Issues and Solutions
- **Network connectivity issues with sigstore/TUF repositories**: Normal in sandboxed environments - disable with `unset CAS_API_KEY`
- **Missing packages in base images**: Expected when not using proper Home Assistant builder environment - use devcontainer for full testing
- **Code signing failures**: Use `unset CAS_API_KEY` or remove codenotary from build.yaml
- **"Can't enable crosscompiling feature" warnings**: Normal and can be ignored in development environments
- **Build failures with package installation**: Often indicates base image version mismatch - check build.yaml vs config.yaml versions

## Validation and Testing

### Manual Validation Requirements
After making changes to any addon:
1. **ALWAYS** lint the Dockerfile: `hadolint -c <addon>/.hadolint.yaml <addon>/Dockerfile`
2. Test configuration validation:
   - YAML configs: `yq -r '.name' <addon>/config.yaml` (should return addon name, not null)
   - JSON configs: `jq -r '.name' <addon>/config.json` (should return addon name, not null)
3. Validate build script recognizes addon: `./build.sh <addon-name>` (should show "Found config.yaml/json")
4. For sambanas addon: 
   - Verify samba configuration options in test/options.json are valid
   - Check that workgroup, username, and network ranges are properly formatted
5. For RPiMySensor addon: 
   - Verify GPIO pin configurations (ce_pin, cs_pin) are within valid ranges (1-26)
   - Validate RF24 settings are acceptable values

### Test Scenarios
- **Sambanas**: 
  - Test configuration loading: `cd sambanas/test && cat options.json` - verify JSON is valid
  - Test samba parameters: workgroup should be valid NetBIOS name, IP ranges should be in CIDR format
  - Verify addon recognizes configuration: `yq -r '.options.workgroup' sambanas/config.yaml`
- **RPiMySensor**: 
  - Validate addon metadata: `jq -r '.arch' RPiMySensor/config.json` - should return array of supported architectures
  - Test GPIO pin ranges: pins should be between 1-26 for Raspberry Pi compatibility
  - Verify channel range: RF24 channel should be 0-125
- **All addons**: 
  - Verify addon is recognized by build system: `./build.sh <addon-name> | head -5`
  - Test Docker syntax: `hadolint -c <addon>/.hadolint.yaml <addon>/Dockerfile`
  - Confirm image name format: should follow `dianlight/{arch}-addon-<slug>` pattern

### Automated Testing
- GitHub Actions automatically build and test on push to devrelease branches
- PR builds test configuration and build success
- Pre-release automation creates development versions with `.dev<number>` suffixes

## Development Workflow

### Making Changes
1. Always work in addon-specific directories
2. Modify configuration files (`config.yaml`, `build.yaml`) as needed
3. Update Dockerfiles following hadolint rules
4. Test locally using scripts in `test/` directory
5. Always lint and validate before committing

### Key Files to Monitor
- `config.yaml` - Addon metadata and options
- `Dockerfile` - Container build instructions
- `rootfs/` directory - Contains addon runtime files
- GitHub workflow files for CI/CD behavior

### Common Gotchas
- **Code signing**: Often fails in development - disable with `unset CAS_API_KEY`
- **Architecture builds**: Default builds for all architectures (armv7, aarch64, amd64) - specify with `archs` variable
- **Base images**: Must match versions in `build.yaml` exactly
- **Network access**: Some builds require internet access for package installation

## CI/CD Pipeline

### Automated Builds
- `docker-image-dev.yml` - Builds development versions from devrelease branches
- `docker-image-pr.yaml` - Validates PR builds
- Uses Home Assistant builder containers with specific environment variables
- Publishes to Docker Hub under dianlight namespace

### Release Process
- Development builds increment version with `.dev<number>`
- Pre-release creates automated PRs for version management
- Production builds require manual triggers or main branch commits

## Important Notes

### Addon Status
- **sambanas**: In maintenance mode - only critical bug fixes
- **RPiMySensor**: Deprecated - no new development
- **plex**: Deprecated - superseded by official Plex addon

### Environment Requirements
- Docker with privileged access for multi-architecture builds
- Home Assistant development environment for full testing
- Network access for package downloads and code signing

### Security Considerations
- All addons run with specific privilege sets defined in config files
- Full access addons (sambanas) require careful security review
- AppArmor profiles control container security boundaries

Always validate your changes thoroughly and never skip the linting step. Build times are significant, so plan accordingly and never cancel long-running builds.

## Common Command Outputs

The following are outputs from frequently run commands. Reference them instead of searching or running bash commands to save time:

### Repository root structure
```
ls -a /home/runner/work/hassio-addons/hassio-addons
.devcontainer  .git  .github  .gitignore  .gitmodules  .vscode  
CODEOWNERS  Hassio_Addons.code-workspace  LICENSE  README.md  
RPiMySensor  addon-plex  build.sh  cosign.pub  plex  
repository.json  sambanas
```

### Sambanas addon structure  
```
ls sambanas/
.hadolint.yaml  CHANGELOG.md  DOCS.md  Dockerfile  README.md  
apparmor.txt  build.yaml  config.yaml  icon.png  logo.png  
rootfs  test  translations
```

### RPiMySensor addon structure
```
ls RPiMySensor/
CHANGELOG.md  Dockerfile  LICENSE  README.md  config.json  
icon.jpeg  logo.png  mysensors.conf  run.sh  test
```

### Addon config validation
```
yq -r '.name' sambanas/config.yaml
# Output: Samba NAS

jq -r '.name' RPiMySensor/config.json  
# Output: RPi MySensor Gateway
```
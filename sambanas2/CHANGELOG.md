# Changelog

## 2026.7.0-rc11

### 🙏 Thanks

- Thanks to all the contributors and users that help to make this addon better.
- Special thanks to supporters and sponsors. With our support I was able to buy a copilot subscription to help me code faster and better.

### 🚨 Notes
- This is a release candidate version, it may contain bugs and issues. Use it at your own risk. It is not recommended to use this version in production environments.
- This version is not compatible with the previous SambaNas addon, it is a complete rewrite and refactor of the addon. It is recommended to backup your configuration before updating to this version.
- This version is only tested with Home Assistant OS and Supervised installations. It may not work properly with Home Assistant Core or Container installations.
- ***Your existing configuration may be lost when updating to this version. Please backup your configuration before updating.***


### 🐭 Features from SRAT [v2026.7.0-rc11](https://github.com/dianlight/srat)

#### 🔧 Chore

- **Migrate to TypeScript 7.0 RC** (Go-based `tsgo` compiler):
  - Updated peer dependency to `typescript: ^7.0.1-rc`
  - Updated `@typescript/native-preview` to `7.0.0-dev.20260701.1`
  - Updated `tsconfig.json`, migration docs, and instruction files
  - Patches `esModuleInterop` default and other TS 7.0 defaults

#### ✨ Features

- **HDIdle per-disk model** (Lab Mode feature): Replaced the global HDIdle
  enable/disable toggle with a fully per-disk configuration model gated behind
  Lab Mode (`experimental_lab_mode=true`). Key changes:
  - **Per-disk enable/disable**: each physical disk has its own HDIdle record
    (`enabled: yes|custom|no`); the service runs automatically when ≥1 disk is
    enabled. The five global `Settings.hdidle_*` fields have been removed.
  - **Dashboard suggestion badge**: HDDs that have not yet been configured show
    an inline "Enable HDIdle?" badge in the disk I/O table (visible only in Lab
    Mode). The badge provides **Ignore** (persists `suggestion_ignored=true`)
    and **Enable** (navigates to the per-disk card in the Volumes page).
  - **Non-rotational guard**: enabling HDIdle on an SSD/NVMe or a device with
    unknown rotational type opens a confirm dialog; accepting persists
    `force_enabled=true` so the warning does not repeat. The backend returns
    HTTP 409 if the flag is missing, preventing accidental spindowns of SSDs.
  - **Rotational detection**: `Disk.is_rotational` tri-state (HDD/SSD/unknown)
    is now derived from `/sys/block/<dev>/queue/rotational` (sysfs primary) with
    SMART `rotation_rate` as fallback. Unknown (e.g. USB enclosures) returns
    `nil` — treated as non-rotational for safety.
  - **Ignore-suggestion endpoint**: `POST /api/disk/{id}/hdidle/ignore-suggestion`
    persists the badge dismissal per disk.
  - **Adaptive polling**: the monitor goroutine polls every 60s when ≥1 disk is
    spun-up and slows to 5min when all monitored disks are already spun-down.
    The goroutine is never started when zero disks are enabled.
  - **readOnly threading**: the per-disk settings card now correctly propagates
    the `readOnly` flag from `VolumeDetailsPanel`.
- **mDNS Registration**: Added optional mDNS registration of the SRAT service for local network discovery. When enabled, the backend registers a `_srat._tcp` service with the system mDNS responder, advertising the service name, port, and metadata. This allows compatible clients to discover the SRAT service on the local network without manual configuration. The feature is controlled by a new `MDNSRegistration` boolean setting in the advanced settings section.

#### 🐛 Bug Fixes

- **HDIdle service permanently broken after first Stop()**: `Stop()` no longer
  leaves `stopChan` non-nil after close. Subsequent `Start()` calls now succeed
  (idempotent). Fixes a latent bug where the service refused to restart after
  any config PUT.
- **Nested mutex deadlock** in `GetDeviceStatus`, `GetProcessStatus`, and
  `observeDiskActivity`: calls to `IsRunning()` under an existing lock now read
  `stopChan` directly to avoid the deadlock inherent in re-acquiring an
  `RWMutex` that is not guaranteed reentrant.
- **`GetDeviceConfig` returned HTTP 500 when service disabled**: the guard
  `!s.config.Enabled → ErrorHDIdleNotSupported` has been removed. The config
  endpoint is now always available for inspection/configuration regardless of
  whether the monitor goroutine is running.
- **`disk_id` injected unsanitised into file path**: `hdidle_handler.go` was
  naïvely prefixing every `disk_id` with `/dev/disk/by-id/` without validation.
  Replaced by `HDIdleServiceInterface.ResolveDevicePath()` which probes three
  candidate paths (absolute `/dev/…`, by-id, kernel name) and rejects inputs
  containing path-traversal characters.

#### 🔄 Breaking Changes

- `Settings.hdidle_enabled`, `hdidle_default_idle_time`, `hdidle_default_command_type`,
  `hdidle_default_power_condition`, and `hdidle_ignore_spin_down_detection` have
  been **removed** from the API and the DB (migration 00017 drops the
  corresponding rows from the `properties` table).
- `POST /api/hdidle/start` and `POST /api/hdidle/stop` have been **removed**.
  The service lifecycle is now fully automatic (driven by the per-disk records).
- `PATCH /api/disk/{id}/hdidle/config` has been **removed** (it was a dead spec
  entry with no handler).

#### 🏗 Chore

- DB migration `00017` (`drop_global_hdidle_properties`): deletes the five
  obsolete global HDIdle property rows. Down migration re-seeds them with their
  original defaults for dev/test rollback.
- `events.PowerEvent` now carries a `Kind PowerEventKind` discriminant field
  (`config` or `status`) so subscribers can branch without comparing zero-values.
- Two new `dto.HDIdleDevice` fields (`SuggestionIgnored`, `ForceEnabled`) and
  matching GORM/generated-layer/converter updates. Schema columns are added by
  GORM `AutoMigrate` on the next startup — no manual migration needed.
- `openapi.json` is **not regenerated** in this branch — it requires a working
  Go toolchain and `go run ./cmd/srat-openapi`. **CI must run**
  `go run ./cmd/srat-openapi -dir=backend/docs` and
  `cd frontend && bun run gen:api` before merging to keep generated artifacts in
  sync. Three hand-edited generated files (`config_to_dto_conv_gen.go`,
  `dto_to_dbom_conv_gen.go`, `g/hdidle_device_config.go`) are aligned with their
  source directives — a `go generate ./...` run will produce the same output.

#### 🔧 Maintenance

- **Multi-variant server release**: Release archives now ship three `srat-server` variants — `srat-server-static` (fully static, zero shared-library dependencies), `srat-server-musl` (dynamic linked against musl libc, built via Zig), and `srat-server-glib` (dynamic linked against glibc, built via CGO). The `srat-server` entry in the archive is a symlink that defaults to `srat-server-static`; the upgrade process automatically updates it to the best available variant for the running system (musl → glibc → static). `srat-openapi` is no longer included in release archives. `srat-cli` is always statically linked.


## 2026.6.0-rc10

### 🏗 Chore
- Update SRAT to v2026.6.0-rc10
- Update Base image to v21.0.0 (Alpine base image to v3.24.0)

### ✨ Features
- New 'Lab Mode' setting in Settings → General section to enable experimental features and configurations for advanced users and testers. When enabled, this setting allows access to features that are still in development or testing phases, providing early access to new functionality while clearly indicating that these features may be unstable or subject to change.

## 2026.5.0-rc9

### 🙏 Thanks

- Thanks to all the contributors and users that help to make this addon better.
- Special thanks to supporters and sponsors. With our support I was able to buy a copilot subscription to help me code faster and better.

### 🚨 Notes
- This is a release candidate version, it may contain bugs and issues. Use it at your own risk. It is not recommended to use this version in production environments.
- This version is not compatible with the previous SambaNas addon, it is a complete rewrite and refactor of the addon. It is recommended to backup your configuration before updating to this version.
- This version is only tested with Home Assistant OS and Supervised installations. It may not work properly with Home Assistant Core or Container installations.
- ***Your existing configuration may be lost when updating to this version. Please backup your configuration before updating.***
- ***If you need HDIdle support don't update and wait future releases.***
- ***If you need Avahi/mDNS support don't update and wait future releases.***

### 🏗 Chore
- Update SRAT to v2026.5.0-rc9

### ✨ Features
- Install [smartmontools-sdk v7.5](https://github.com/dianlight/smartmontools-sdk) (`libsmartmon.a` + headers) providing in-process SMART device access without spawning a subprocess
- Set `LIBRARY_PATH` and `CPATH` environment variables for all container processes so that components linking against `libsmartmon` are automatically found
- Register `/etc/profile.d/smartmontools-sdk.sh` so interactive login shells also inherit the correct library and include paths

## 2026.5.0-rc8

### 🏗 Chore
- Update SRAT to v2026.5.0-rc8

## 2026.5.0-rc7

### 🏗 Chore
- Update SRAT to v2026.5.0-rc7
- Update homeassistant client to 5.1.0

### ✨ Features
- Add a allert when Protected Mode is enabled in Home Assistant (See [DOCS](DOCS.md) )

## 2026.5.0-rc6 

### 🏗 Chore
- Update SRAT to v2026.5.0-rc6

## 2026.5.0-rc5

#### 🏗 Chore
- Update SRAT to v2026.5.0-rc5

### 🐭 Features from SRAT [v2026.5.0-rc5](https://github.com/dianlight/srat)

#### ✨ Features

- New startup wizard for first-run configuration of essential Samba settings (hostname, workgroup, admin password) and optional telemetry opt-in. The wizard is implemented as a multi-step dialog with a progress stepper and integrated with the existing guided tour system for contextual help. It is accessible from the Settings page and automatically shown on first run.

#### 🐛 Bug Fixes

#### 🏗 Chore

## 2026.4.0-rc4

Internal release for testing and finalization of 2026.4.0-rc3 changes. No public changes since 2026.4.0-rc3.

## 2026.4.0-rc3

### 💥 Breaking Changes

- **Container registry changed**: images are now published to `ghcr.io/dianlight/` (GitHub Container Registry) instead of `docker.io/dianlight/` (Docker Hub). The addon store URL in Home Assistant must be updated.
- **Image renamed**: the per-architecture image prefix has been dropped. Old image: `dianlight/{arch}-addon-sambanas2`. New image: `ghcr.io/dianlight/addon-sambanas2`. The multi-arch manifest is resolved automatically; no architecture-specific tag is needed.

### 🔄 Migration Notes

If you are pulling the image directly (outside of HA Supervisor), update your image reference from `docker.io/dianlight/amd64-addon-sambanas2:<tag>` to `ghcr.io/dianlight/addon-sambanas2:<tag>`.

### 🐭 Features from SRAT [v2026.4.0-rc2](https://github.com/dianlight/srat)

> **Note**: This section tracks development progress and changes planned for the first Release Candidate (RC). The final release notes will be organized and consolidated once the RC is ready for public testing.

#### ✨ Features

- **Interface IP Resolution**: Samba configuration now resolves network interface names to IP addresses at generation time, ensuring IPv4 preference is honored. The `--ipv4-only` CLI flag allows disabling IPv6 addresses in the `interfaces` directive. This prevents issues where interface names could resolve to IPv6 addresses, causing connectivity problems when IPv4 is preferred.
- **HACS Custom Component**: Added a Home Assistant custom component (`custom_components/srat/`) compatible with HACS for direct integration with Home Assistant. Supports UI configuration wizard, Supervisor add-on autodiscovery via slug whitelist, WebSocket-based real-time updates, and exposes sensors compatible with the existing SRAT HA integration (samba status, process status, volume status, disk health, per-disk I/O, and per-partition health). Includes full test suite using `pytest-homeassistant-custom-component` and Python code quality tooling (ruff, mypy) integrated into CI. *Early internal implementation serving as the foundation for upcoming releases.*
- **Report Issue on GitHub**: Added new "Report Issue" functionality allowing users to easily create GitHub issues with automated diagnostic data collection:
  - Button in top navigation bar to open issue reporting dialog
  - Problem type selector (Frontend UI, HA Integration, Addon, or Samba problems)
  - Markdown-compatible description field
  - Optional data collection: contextual data (URL, navigation history, browser info, console errors), addon logs, and sanitized SRAT configuration
  - Automatic routing to appropriate repository (dianlight/srat or dianlight/hassos-addon) based on problem type
  - Pre-populated GitHub issue URL with diagnostic information
  - Downloads diagnostic files for attachment to the issue
- **Autoupdate with Signature Verification (#358)**: Implemented a new autoupdate mechanism using minio/selfupdate with cryptographic signature verification:
  - Added `--auto-update` flag to automatically download and apply updates without user acceptance
  - Updates are signed with minisign (Ed25519) signatures for security
  - Automatic restart when running under s6 supervision
  - Public key is embedded in the binary for signature verification
  - Build workflow automatically signs all release binaries
- **Allow Guest Setting**: Added new `Allow Guest` boolean setting in Settings → General section to enable anonymous guest access to Samba shares. When enabled, configures Samba with `guest account = nobody` and `map to guest = Bad User` for secure guest authentication.
- **Enhanced SMART Service [#234](https://github.com/dianlight/srat/issues/234)**: Implemented comprehensive SMART disk monitoring and control features including health assessment, temperature monitoring, and attribute tracking.
- **SMB over QUIC Support [#227](https://github.com/dianlight/srat/issues/227)**: Added comprehensive support for SMB over QUIC transport protocol with intelligent system detection and automatic fallback to TCP when QUIC is unavailable.
- **Autoupdate Service**: Implemented a back-end service for automatic updates from GitHub releases, with support for multiple channels (stable, beta, dev) and local development builds.
- **Telemetry Configuration**: Added UI in Settings to configure telemetry modes (Rollbar error tracking), dependent on internet connectivity and user consent.
- **Volume Mount Intelligence**: Enriched volume mount structs with partition and filesystem metadata to enable informed NFS vs CIFS export decisions and implemented proper volume-event handling for cache retry and invalidation. ([#500](https://github.com/dianlight/srat/issues/500))
- **Bidirectional Home Assistant WebSocket**: Introduced client-to-server WebSocket messaging, starting with a `helo` handshake that allows the custom component to announce its identity and version to the backend. ([#508](https://github.com/dianlight/srat/issues/508))
- **Disable SMART Integration Setting**: Added a new setting to disable SMART integration, helping mitigate excessive disk wake-ups in sleeping-disk scenarios. ([#499](https://github.com/dianlight/srat/issues/499))
- **Home Assistant Repairs Proxy Service**: Implemented a backend service to manage Home Assistant repairs via the custom component, with queued commands and lifecycle synchronization over WebSocket. ([#518](https://github.com/dianlight/srat/issues/518))
- **Overlay Helper System Improvements**: Refactored the TourEvents system for better accuracy and type safety, added comprehensive tests, and established frontend maintenance guidelines. ([#515](https://github.com/dianlight/srat/issues/515))
- Add repair service and proxy for Home Assistant integration

#### 🐛 Bug Fixes

- **HA Config Flow Discovery Import**: Fixed Supervisor discovery flow import errors by using the new `HassioServiceInfo` module path with a compatibility fallback for older Home Assistant versions.
- **Udev Event Parsing Error Handling**: Improved handling of malformed udev events to prevent spurious error reports to Rollbar. Malformed events with invalid environment data are now logged at debug level instead of error level, reducing noise in error tracking while maintaining visibility for legitimate errors.
- **Issue Report Gist Offloading**: Fixed oversized issue report URLs by replacing large addon log and console error parameters with Gist links, preventing runaway URL growth when diagnostics are large.
- **Mount Point Type Defaulting**: Default missing mount point types on events to avoid NOT NULL constraint failures when persisting mount points.
- **Mount Conversion Type Derivation**: Ensure mount conversions derive mount point type from the mount path to prevent missing type values.
- **WebSocket Loading State**: Report WebSocket SSE loading as active until the socket is connected, and re-enable loading after disconnects.
- **Deterministic Mount Flag Metadata**: Ensure mount-flag metadata for shared options (for example, uid/gid) is derived from a consistent preferred adapter source to avoid nondeterministic descriptions and regex values.
- **Volumes TreeView ID Collisions**: Namespace volume tree item IDs by disk to prevent duplicate partition identifiers from crashing the Volumes tab.
- **Disk FSCK Status Population**: Populate fsck supported/needed fields in disk stats using filesystem service capability and state information.

#### 🔄 Breaking Changes

- **Update Engine Replacement**: Replaced jpillora/overseer with minio/selfupdate for binary updates. The new implementation provides more reliable updates with cryptographic signature verification using minisign. Updates will now properly restart the service when running under s6 supervision.
- **SMB over QUIC Default Behavior Change**: The SMB over QUIC feature is now disabled by default. Users must explicitly enable it in the settings to use this functionality. This change aims to enhance security and stability by preventing unintended use of the experimental protocol.
- **Telemetry Service Update**: The telemetry service has been updated to use Rollbar for error tracking and monitoring. This change may require users to review their privacy settings and consent to data collection, as Rollbar collects different types of data compared to the previous telemetry solution.
- **Autoupdate Service Modification**: The autoupdate service has been modified to support multiple update channels (stable, beta, dev) and local development builds. Users may need to reconfigure their update preferences to align with the new channel system.
- **Disk Health Payload Update**: Per-partition disk health now reports `filesystem_state` and no longer includes the redundant `fsck_needed` field.
- **Partition Filesystem Support**: Per-partition disk health no longer includes `fsck_supported`; filesystem support is now reported on partitions as `filesystem_support`.

#### 🔧 Maintenance

- **Custom Component Build Tooling**: Added ruff (lint + format) and mypy (type checking) tooling for the HA custom component with `pyproject.toml` configuration, `Makefile` targets (`make check`, `make lint`, `make format`, `make typecheck`), and CI integration in `validate-hacs.yaml`. Fixed all lint and type issues in existing code.
- **Go 1.26 Migration**: Upgraded Go version from 1.25.7 to 1.26.0, adopting new language features:
  - Replaced all `pointer.Bool/String/Int/Uint64/Of/Any()` calls with Go 1.26's built-in `new(expr)` syntax (~268 occurrences) and removed the `xorcare/pointer` dependency
  - Replaced all `interface{}` with `any` alias (147 occurrences) following Go modernizer patterns
  - Replaced `sync.WaitGroup` `Add(1)/Done()` patterns with `WaitGroup.Go()` method in production code
- **TypeScript 6.0 Final Migration**: Updated frontend TypeScript configuration for compatibility with TypeScript 6.0 final (March 23, 2026) and preparation for TypeScript 7.0 (Go-based):
  - Removed all deprecated compiler flags (`experimentalDecorators`, `useDefineForClassFields`, `baseUrl`, `outFile`)
  - Updated ECMAScript target from ES2021 to ES2022 for better modern feature alignment
  - Enabled `noImplicitOverride` strict flag (code already compliant)
  - Code optimizations leveraging TS 6.0 improved type inference (removed 11 unnecessary type assertions)
  - Updated `peerDependencies` to support TypeScript 6.0 final
  - Created comprehensive migration guide (`frontend/TYPESCRIPT_MIGRATION.md`) documenting completed work and remaining tasks for full TS 7.0 readiness
  - Project uses `@typescript/native-preview` (tsgo) for type checking
  - TypeScript 6.0 final is the last JavaScript-based version before the Go-native 7.0 compiler
- Updated dependencies to latest versions to ensure security and compatibility.

#### 🏗 Chore

- Replace snapd osutil dependency with internal mount utilities based on moby/sys/mountinfo <!-- cspell:disable-line -->
- Align UI elements to HA [#81](https://github.com/dianlight/srat/issues/81)
- Create the base documentation [#80](https://github.com/dianlight/srat/issues/80)
- Display version from ADDON


## 2026.4.0-rc2

### 🏗 Chore

- General code refactor and cleanup
- Update dependencies and base image
- Add more logging and error handling
- Add more documentation and examples
- Add more tests and CI/CD pipelines

## 2026.3.0-rc1

#### 💥 Breaking Changes (from SambaNas addon)
- New configuration format (See [DOCS](DOCS.md) )
- Remove support to armv7 architecture
- Remove HDIdle support (for now is added back in future releases)
- Remove Avahi/mDNS support (due to side effects on some systems)

###  ✨ Features (from SambaNas addon)
- Brand New icon and logo AI Generated
- New option `use_external_kernel_modules` (default: false) to downloads extra kernel modules from
[https://github.com/dianlight/hasos_more_modules](https://github.com/dianlight/hasos_more_modules) (See [DOCS](DOCS.md) )
- New option `srat_update_channel`to manage SRAT Update (EXPERIMENTAL [DOCS](DOCS.md) )
- New option `auto_update` (default: true) to automatically download and install SRAT updates
- New option `factory_reset` (default: false) to delete all configurations, settings, and database (See [DOCS](DOCS.md) )
- New UI (SRAT) to read and control the addon. (See [SRAT Repository](https://github.com/dianlight/srat) )
- Support Wsdd-native for better Windows Discovery (Remove WSDD and WSDD2 due to instability)
- Automatic modprobe for all kernel fs
- Add ability to use Custom Samba Version - Custom Build Only 
- Add new IPv6 disable option to disable IPv6 stack inside the addon (See [DOCS](DOCS.md) )
- Experimental NFS server support via s6; exports auto-managed by SRAT for Media/Backup/Share share types (internal HA-addon use only)

### 🏗 Chore


[docs]: https://github.com/dianlight/hassio-addons/blob/master/sambanas2/DOCS.md

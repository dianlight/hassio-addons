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


### 🐭 Features from SRAT [v2026.5.0-rc6](https://github.com/dianlight/srat)

#### 🐛 Bug Fixes
- Fix compile issue in github actions that was cause of freezed UI in some cases.


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

### 🐭 Features from SRAT [v2026.5.0-rc5](https://github.com/dianlight/srat)

#### ✨ Features

- New startup wizard for first-run configuration of essential Samba settings (hostname, workgroup, admin password) and optional telemetry opt-in. The wizard is implemented as a multi-step dialog with a progress stepper and integrated with the existing guided tour system for contextual help. It is accessible from the Settings page and automatically shown on first run.

#### 🐛 Bug Fixes

#### 🏗 Chore


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

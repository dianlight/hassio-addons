# Changelog

## Unreleased

### 🏗 Chore
- Automated `CHANGELOG.md` maintenance: new `opencode-changelog` workflow (no `/oc` commands) resolves the model via `dianlight/opencode-modelselect-action` (`docs`/`auto`, `OPENCODE_API_KEY`) and curates user-important entries per `sambanas2/.changelog-style.md`. `devrelease` keeps `## Unreleased`; `mergerelease` strips it and bumps beta (`PATCH+1`, calendar rollover in October); `prerelease` is created only for new versions (Us2/Us3).
- Fix `docker-image-pr` version check to skip `## Unreleased` when comparing `config.yaml` with the changelog head.
- `🙏 Thanks` is always first and `🚨 Notes` always second in the first versioned release; enforced by `scripts/normalize_changelog_order.py` in the changelog workflow.
- Removed the `🐭 Features from SRAT` section (retired `scripts/update_srat_changelog.sh`): the used SRAT version is referenced in `🏗 Chore` with a link to the full upstream changelog, and only important SRAT changes are reported in `✨ Features` / `🐛 Bug Fixes` as `(from SRAT v...)` items curated by the AI changelog action.
- Refactor `opencode-changelog` workflow into a generic engine: shared logic (SRAT fetch, prompt rendering, opencode run, normalize) moved to `.github/scripts/opencode-maintain-changelog.sh` (parameterized by add-on, proven on `sambanas2` first), the normalizer promoted to `.github/scripts/normalize_changelog_order.py` (old path kept as a shim), and per-add-on conventions stay in `<addon>/.changelog-style.md`. Nothing changelog-related lives in `<addon>/scripts/`, so dev builds never auto-execute it.

### 🐛 Bug Fixes
- Fix Docker dev build failure (`libcrypto3`/`libssl3` 3.5.7 vs `openssl` 3.5.8 conflict) by running `apk upgrade --no-cache` before `apk add` in the Samba install stage and builder stages.

## 2026.9.0-rc14

### 🙏 Thanks

- Thanks to all the contributors and users that help to make this app better.
- Special thanks to supporters and sponsors. With our support I was able to buy an opencode-go subscription to help me code faster and better.

### 🚨 Notes
- This is a release candidate version, it may contain bugs and issues. Use it at your own risk. It is not recommended to use this version in production environments.

### 🐛 Bug Fixes
- Improved hardware service stability

## 2026.8.0-rc13

### 🏗 Chore
- Update [smartmontools-sdk](https://github.com/dianlight/smartmontools-sdk) to the new monorepo layout and release model: the SDK now ships as native-core releases (version scheme `v<AC_INIT>.<N>`), replacing the retired standalone `v7.5` tag. The release tarball additionally includes the `libsmartmon_go.so` C ABI wrapper shared library.
- Track the smartmontools-sdk **dev channel**: pin the latest prerelease build `v8.0.2-pre.514` instead of the stable `v8.0.x` line.
- Add a Renovate custom manager for `SMARTMONTOOLS_SDK_VERSION` so dependency updates are proposed automatically, with prereleases allowed for `dianlight/smartmontools-sdk`.

#### 🐛 Bug Fixes
- Fix [#729](https://github.com/dianlight/hassio-addons/issues/729) 🐛 [SAMBA NAS2 - beta] Failing to load - Nil pointer in hardwareService
- Fix [#727](https://github.com/dianlight/hassio-addons/issues/727) ❓ [addon] Upgrade from version 1

## 2026.8.0-rc12

### 🚨 Notes
- This is a release candidate version, it may contain bugs and issues. Use it at your own risk. It is not recommended to use this version in production environments.
- This version is not compatible with the previous SambaNas addon, it is a complete rewrite and refactor of the addon. It is recommended to backup your configuration before updating to this version.
- This version is only tested with Home Assistant OS and Supervised installations. It may not work properly with Home Assistant Core or Container installations.
- ***Your existing configuration may be lost when updating to this version. Please backup your configuration before updating.***

### 💥 Breaking Changes

- **Minimum Home Assistant version raised to `2026.4.0`** (previously `2025.8.0`), following the "add-on" to "app" rename in Home Assistant and the new Supervisor mount layout.
- **Shares and map entries renamed to match the Home Assistant "app" rebranding**:
  - Share `addons` -> `local_apps` (mounted at `/local_apps`)
  - Share `addon_configs` -> `app_configs` (mounted at `/app_configs`)
  - Map entries: `addons:rw` -> `local_apps:rw`, `addon_config:rw` -> `app_config:rw`, `all_addon_configs:rw` -> `all_app_configs:rw`

### 🔄 Migration Notes

- The `addons` and `addon_configs` shares are renamed to `local_apps` and `app_configs`, preserving their configured users and settings.
- SMB clients connecting to the `addons` or `addon_configs` shares must use the new `local_apps` / `app_configs` names.
- Update Home Assistant to 2026.4.0 or newer before installing this version.

### 🏗 Chore
- Update SRAT to v2026.8.0-rc12

#### 🐛 Bug Fixes
- Fix [#726](https://github.com/.../issues/726) [Samba NAS2] No way to manually mount disk

## 2026.7.0-rc11

### 🏗 Chore
- Update SRAT to v2026.7.0-rc11

## 2026.6.0-rc10

### 🏗 Chore
- Update SRAT to v2026.6.0-rc10
- Update Base image to v21.0.0 (Alpine base image to v3.24.0)

### ✨ Features
- New 'Lab Mode' setting in Settings → General section to enable experimental features and configurations for advanced users and testers. When enabled, this setting allows access to features that are still in development or testing phases, providing early access to new functionality while clearly indicating that these features may be unstable or subject to change.

## 2026.5.0-rc9

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

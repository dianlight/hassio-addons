# Changelog

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


### 🐭 Features from SRAT [v2026.5.0-rc9](https://github.com/dianlight/srat)

#### ✨ Features
- **Lab Mode**: Added a new "Lab Mode" section in Settings → Advanced with experimental features that can be enabled for testing and feedback. 
- **SMART Integration Mode**: Replaced the `disable_smart` boolean toggle with a 3-option `smart_mode` enum (`none`, `legacy`, `direct`).
  - `none`: SMART integration disabled.
  - `legacy`: Uses the `smartctl` executable (previous default behavior).
  - `direct`: Uses the `libsmartmon_go.so` library back end (lab feature, requires lib availability at startup).
  - The `direct` option is only shown in the UI when experimental lab mode is enabled and `libsmartmon_go.so` is detected at runtime.
  - Backend detects `libsmartmon_go.so` availability at startup and exposes `lib_smart_available` in the settings API response.
  - DB migration 00016 converts existing `DisableSmart` boolean properties to the new `smart_mode` string value.

#### 🐛 Bug Fixes

#### 🏗 Chore

- **Static binary portability**: Default production builds (`CGO_ENABLED=0`) are now fully statically linked with zero shared-library dependencies, running unchanged on GNU/Linux systems using either glibc (Debian, Ubuntu) or musl (Alpine). The `libsmartmon_go.so` lib integration is now gated behind a new `smartlib` build tag so it no longer forces `libdl.so.2` dynamic linking in release binaries. Build with `--cgo` (which adds `-tags smartlib`) to opt in to the lib mode.


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

# Changelog

## 2026.3.0-rc1

### 🙏 Thanks

- Thanks to all the contributors and users that help to make this addon better.
- Special thanks to supporters and sponsors. With our support I was able to buy a copilot subscription to help me code faster and better.

### 🚨 Notes
- This is a release candidate version, it may contain bugs and issues. Use it at your own risk. It is not recommended to use this version in production environments.
- This version is not compatible with the previous SambaNas addon, it is a complete rewrite and refactor of the addon. It is recommended to backup your configuration before updating to this version.
- This version is only compatible with Home Assistant OS and Supervised installations, it is not compatible with Home Assistant Core or Container installations.
- This has been a big refactor to make the addon more efficient and use less resources. Some features have been removed or changed to improve stability and performance. Some will be added back in future releases.
- ***Your existing configuration will be lost when updating to this version. Please backup your configuration before updating.***
- ***If you need HDIdle support don't update and wait next releases.***
- ***If you need Avahi/mDNS support don't update and wait next releases.***
- ***If you are using armv7 architecture don't update and wait next releases.***

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

### 🐭 Features from SRAT [v2026.3.0-dev.3](https://github.com/dianlight/srat)

> **Note**: This section tracks development progress and changes planned for the first Release Candidate (RC). The final release notes will be organized and consolidated once the RC is ready for public testing.

#### 🙏 Thanks

We would like to thank all supporters for their contributions and donations.
With your donations, we are able to continue developing and improving this project. Your support is greatly appreciated.

#### 📅 Roadmap

- **Release Candidate (RC) Planned for March**: The first release candidate version is scheduled for March. This RC will stabilize the codebase, finalize the API, and provide a feature-complete version for community testing and feedback before the official stable release.

#### ✨ Features

- **HACS Custom Component**: Added a Home Assistant custom component (`custom_components/srat/`) compatible with HACS for direct integration with Home Assistant. Supports UI configuration wizard, Supervisor add-on autodiscovery via slug whitelist, WebSocket-based real-time updates, and exposes sensors compatible with the existing SRAT HA integration (samba status, process status, volume status, disk health, per-disk I/O, and per-partition health). Includes full test suite using `pytest-homeassistant-custom-component` and Python code quality tooling (ruff, mypy) integrated into CI. *Early internal implementation serving as the foundation for upcoming releases.*

#### 🧑‍🏫 Documentation

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
- Updated dependencies to latest versions to ensure security and compatibility.

#### ✨ Features

- **Report Issue on GitHub**: Added new "Report Issue" functionality allowing users to easily create GitHub issues with automated diagnostic data collection:
  - Button in top navigation bar to open issue reporting dialog
  - Problem type selector (Frontend UI, HA Integration, Addon, or Samba problems)
  - Markdown-compatible description field
  - Optional data collection: contextual data (URL, navigation history, browser info, console errors), addon logs, and sanitized SRAT configuration
  - Automatic routing to appropriate repository (dianlight/srat or dianlight/hassos-addon) based on problem type
  - Pre-populated GitHub issue URL with diagnostic information
  - Downloads diagnostic files for attachment to the issue
- **Autoupdate with Signature Verification (#358)**: Implemented a new autoupdate mechanism using minio/selfupdate with cryptographic signature verification
  - Added `--auto-update` flag to automatically download and apply updates without user acceptance
  - Updates are signed with minisign (Ed25519) signatures for security
  - Automatic restart when running under s6 supervision
  - Public key is embedded in the binary for signature verification
  - Build workflow automatically signs all release binaries
- **Allow Guest Setting**: Added new `Allow Guest` boolean setting in Settings → General section to enable anonymous guest access to Samba shares. When enabled, configures Samba with `guest account = nobody` and `map to guest = Bad User` for secure guest authentication.
- **Enhanced SMART Service [#234](https://github.com/dianlight/srat/issues/234)**: Implemented comprehensive SMART disk monitoring and control features:
- **SMB over QUIC Support [#227](https://github.com/dianlight/srat/issues/227)**: Added comprehensive support for SMB over QUIC transport protocol with intelligent system detection
- **Autoupdate Service**: Implemented a back-end service for automatic updates from GitHub releases, with support for multiple channels and local development builds.
- **Telemetry Configuration**: Added UI in Settings to configure telemetry modes, dependent on internet connectivity.
- Manage `local master` option (?)
- Add Rollbar telemetry service for error tracking and monitoring
- Help screen or overlay help/tour [#82](https://github.com/dianlight/srat/issues/82)
- Smart Control [#100](https://github.com/dianlight/srat/issues/100)
- HDD Spin down [#101](https://github.com/dianlight/srat/issues/101)

#### 🏗 Chore

- Replace snapd osutil dependency with internal mount utilities based on moby/sys/mountinfo <!-- cspell:disable-line -->
- Align UI elements to HA [#81](https://github.com/dianlight/srat/issues/81)
- Create the base documentation [#80](https://github.com/dianlight/srat/issues/80)
- Display version from ADDON

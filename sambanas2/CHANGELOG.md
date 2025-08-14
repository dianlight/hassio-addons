# Changelog

## 2025.8.0-dev [ 🚧 Unreleased ]

###  ✨ Features
- Brand New icon and logo AI Generated
- New option `srat_update_channel`to manage SRAT Update (EXPERIMENTAL [DOCS](DOCS.md) )
- New UI (SRAT) to read and control the addon. (See [SRAT Repository](https://github.com/dianlight/srat) )
- Announce Samba service via Avahi/mDNS for better discovery
- Support ~~WSDD~~ and WSDD2
#### __🚧 Work in progess__
- [ ] ACL For folders [#208](https://github.com/dianlight/hassio-addons/issues/208)
- [ ] Migrate config from SambaNas addon

### 🏗 Chore
- Fork SambaNas to the new SambaNas2 addon
- New version model
#### __🚧 Work in progess__
- [x] Update the documentation
    - [ ] Tutorial screenshots?
- [ ] En translation 

### 🐭 Features from SRAT [v2025.8.0-dev.5](https://github.com/dianlight/srat)

#### ✨ Features

- Manage `recycle bin`option for share
- Manage WSDD2 service
- Manage Avahi service
- Veto files for share not global [#79](https://github.com/dianlight/srat/issues/79)
- Ingress security validation [#89](https://github.com/dianlight/srat/issues/89)
- Dashboard
- Frontend: Async console.error callbacks & React hook — added a registry to register callbacks executed asynchronously whenever `console.error` is called, plus `useConsoleErrorCallback` hook for easy integration in components.
- **Enhanced TLog Package [#152](https://github.com/dianlight/srat/issues/152)**: Complete logging system overhaul with advanced formatting capabilities:
  - Added support for `github.com/k0kubun/pp/v3` for enhanced pretty printing
  - Integrated `samber/slog-formatter` for professional-grade log formatting
  - Enhanced error formatting with structured display and tree-formatted stack traces for `tozd/go/errors`
  - Automatic terminal detection for color support
  - Sensitive data protection (automatic masking of passwords, tokens, API keys, IP addresses)
  - Custom time formatting with multiple preset options
  - Enhanced context value extraction and display
  - HTTP request/response formatting for web applications
  - Comprehensive color support with level-based coloring (TRACE=Gray, DEBUG=Cyan, INFO=Green, etc.)
  - Thread-safe configuration management
  - Backward compatibility maintained with existing code
- Add Rollbar telemetry service for error tracking and monitoring

##### **🚧 Work in progress**

- [ ] Manage `local master` option (?)
- [ ] Help screen or overlay help/tour [#82](https://github.com/dianlight/srat/issues/82)
- [ ] Custom component [#83](https://github.com/dianlight/srat/issues/83)
- [x] Smart Control [#100](https://github.com/dianlight/srat/issues/100)
- [x] HDD Spin down [#101](https://github.com/dianlight/srat/issues/101)

#### 🐛 Bug Fixes

- `enable`/`disable` share functionality is not working as expected.
- Renaming the admin user does not correctly create the new user or rename the existing one; issues persist until a full addon reboot.
- Fix dianlight/hassio-addons#448 [SambaNAS2] Unable to create share for mounted volume
- Fix dianlight/hassio-addons#447 [SambaNAS2] Unable to mount external drive
- **Disk Stats Service**: Changed log level from `Error` to `Warn` for disk stats update failures to reduce log noise and better distinguish between critical errors and warnings
- **SQLite concurrency lock (SQLITE_BUSY) resolved [#164](https://github.com/dianlight/srat/issues/164)**: Hardened database configuration to prevent intermittent "database is locked" errors when reading mount points under concurrent load. Changes include enabling WAL mode, setting `busy_timeout=5000ms`, using `synchronous=NORMAL`, and constraining the connection pool to a single open/idle connection. Added repository-level RWMutex guards and a concurrency stress test.

##### **🚧 Work in progress**

- [W] Addon protected mode check [#85](https://github.com/dianlight/srat/issues/85)

#### 🏗 Chore

- Implement watchdog
- Align UI elements to HA [#81](https://github.com/dianlight/srat/issues/81)
- **Dependencies**: Updated Go dependencies including:
  - Added `github.com/k0kubun/pp/v3` v3.5.0 for pretty printing
  - Updated `github.com/samber/lo` to v1.51.0
  - Added `github.com/samber/slog-common` v0.19.0 for enhanced logging functionality
  - Added gohack replace directives for `samber/slog-http` and `jpillora/overseer` for development

##### **🚧 Work in progress**

- [ ] Create the base documentation [#80](https://github.com/dianlight/srat/issues/80)
- [ ] Display version from ADDON

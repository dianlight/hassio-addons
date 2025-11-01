# Changelog

## 2025.10.0-dev [ 🚧 Unreleased ]

###  ✨ Features
- Brand New icon and logo AI Generated
- New option `srat_update_channel`to manage SRAT Update (EXPERIMENTAL [DOCS](DOCS.md) )
- New UI (SRAT) to read and control the addon. (See [SRAT Repository](https://github.com/dianlight/srat) )
- ~~Announce Samba service via Avahi/mDNS for better discovery~~ Remove for side effects
- Support ~~WSDD~~ and WSDD2
- Automatic modprobe for all kernel fs
#### __🚧 Work in progess__
- [x] Add ability to use Custom Samba Version 
- [ ] Migrate config from SambaNas addon

### 🏗 Chore
- Fork SambaNas to the new SambaNas2 addon
- New version model
- 
#### __🚧 Work in progess__
- [x] Upgrade Samba to 4.23.1 
- [x] Update the documentation
    - [x] Tutorial screenshots?
- [x] En translation 

### 🐭 Features from SRAT [v2025.10.0-dev.1](https://github.com/dianlight/srat)

#### � Documentation

- **Frontend Testing Standards**: Updated documentation and Copilot instructions to mandate `@testing-library/user-event` for all user interactions in tests. The deprecated `fireEvent` API is now strictly prohibited in all new and modified tests. Updated files:
  - `.github/copilot-instructions.md`: Added userEvent requirements to Testing Library Standards and Component Testing Pattern sections
  - `docs/TEST_COVERAGE.md`: Added userEvent to Framework & Tools and Frontend Testing Best Practices
  - `frontend/README.md`: Added Testing Standards section with userEvent requirement

#### �🐛 Bug Fixes

- **Udev Event Parsing Error Handling**: Improved handling of malformed udev events to prevent spurious error reports to Rollbar. Malformed events with invalid environment data are now logged at debug level instead of error level, reducing noise in error tracking while maintaining visibility for legitimate errors.

#### 🔄 Breaking Changes

- **Rollbar v3.0.0-beta.4 Migration**: Updated Rollbar session replay configuration from `recorder` to `replay` to align with Rollbar.js v3.0.0-beta.4. This is an internal configuration change that does not affect end users.

#### 🔧 Maintenance

- **Samba Version-Aware Configuration**: Implemented comprehensive Samba version checking in smb.conf template generation:
  - Added `GetSambaVersion()` and `IsSambaVersionAtLeast()` utilities in `osutil` package
  - Template context now includes `samba_version` and `samba_version_sufficient` variables
  - Added template functions: `versionAtLeast()` and `versionBetween()` for conditional configuration
  - Conditional includes for version-specific options:
    - **Samba 4.23+**: `server smb transports` with QUIC support
    - **Samba 4.21-4.22**: Legacy transport configuration (no QUIC)
    - **Samba < 4.22**: Include `fruit:posix_rename` option
    - **Samba 4.22+**: Exclude `fruit:posix_rename` (removed due to Windows client issues)
  - Fallback to conservative defaults when version cannot be determined
  - Added detailed documentation: `docs/SAMBA_VERSION_CHECKS.md`
  - Prevents configuration errors across different Samba versions (4.21, 4.22, 4.23+)
- **Dependency Cleanup**: Replaced deprecated `github.com/inconshreveable/go-update` library (last updated 2016) with standard Go library functions for binary updates. This reduces external dependencies and improves maintainability without affecting functionality.
- **Redux DevTools Integration**: Removed unused `@redux-devtools/extension` package. Redux Toolkit's `configureStore()` provides built-in Redux DevTools support, making the separate extension package unnecessary. DevTools integration continues to work seamlessly in development mode.

#### ✨ Features

- **Enhanced SMART Service [#234](https://github.com/dianlight/srat/issues/234)**: Implemented comprehensive SMART disk monitoring and control features:
  - **Health Status Monitoring**: Added `GetHealthStatus()` method to evaluate disk health by comparing SMART attributes against thresholds
  - **Self-Test Execution**: Added `StartSelfTest()` method to initiate short, long, or conveyance SMART self-tests on SATA devices
  - **Test Status Monitoring**: Added `GetTestStatus()` method to retrieve current or last SMART self-test results
  - **SMART Control**: Added `EnableSMART()` and `DisableSMART()` methods for controlling SMART functionality on SATA devices
  - **SMART Enabled Status Tracking**: Added `Enabled` field to `SmartInfo` DTO to track whether SMART is currently active on the disk
  - **Pre-Failure Alerts**: Integrated with tlog callback system to automatically log warnings when disk health checks detect failing attributes
  - **Cross-Platform Support**: Linux-specific ioctl implementations with graceful fallback on other platforms
  - **New DTOs**: Added `SmartTestType`, `SmartTestStatus`, and `SmartHealthStatus` types for SMART operations
  - **Enhanced Error Handling**: Added `ErrorSMARTOperationFailed` and `ErrorSMARTTestInProgress` error codes
  - **REST API Endpoints**: Implemented 7 new REST endpoints for SMART operations:
    - `GET /disk/{disk_id}/smart/info` - Retrieve SMART information
    - `GET /disk/{disk_id}/smart/health` - Get disk health status
    - `GET /disk/{disk_id}/smart/test` - Retrieve test status
    - `POST /disk/{disk_id}/smart/test/start` - Start SMART self-test
    - `POST /disk/{disk_id}/smart/test/abort` - Abort running test
    - `POST /disk/{disk_id}/smart/enable` - Enable SMART
    - `POST /disk/{disk_id}/smart/disable` - Disable SMART
  - **Frontend Integration**: Added `SmartStatusPanel` component with:
    - Temperature monitoring and thresholds
    - Power statistics display
    - Health status with failing attribute details
    - Self-test status and progress tracking
    - Action buttons with intelligent enable/disable logic based on SMART state
    - Start test dialog with test type selection
  - **Smart Button State Management**: Enable/Disable SMART buttons intelligently:
    - "Enable SMART" button disabled when SMART is already active
    - "Disable SMART" button disabled when SMART is not active
    - Tooltips explain button disabled states
  - **Verified proper usage of `github.com/anatol/smart.go` library and extended functionality for disk management needs
- **Native Bun Hot-Reloading**: Removed external `bun-html-live-reload` library and configured Bun's native development server with HMR:
  - Removed dependency on `bun-html-live-reload` package
  - Enabled Bun's native HMR via `development: { console: true, hmr: true }` configuration
  - Leverages Bun's `--hot` flag for build script auto-reload on source changes
  - Simplified development server setup using Bun's built-in capabilities
  - Reduced dependency footprint with native implementation
- **Reduced Database Dependencies [#208](https://github.com/dianlight/srat/issues/208)**: Optimized CLI command database requirements:
  - **version command**: No database needed - runs without any DB initialization
  - **upgrade command**: Uses in-memory database by default - no file path required
  - **start/stop commands**: Continue to require persistent database file
  - Improved startup performance for version checks
  - Simplified command-line usage for common operations
- **SMB over QUIC Support [#227](https://github.com/dianlight/srat/issues/227)**: Added comprehensive support for SMB over QUIC transport protocol with intelligent system detection:
  - **Samba Version Check**: Requires Samba 4.23.0 or later for QUIC support
  - **Kernel Module Detection**: Automatically detects QUIC kernel module (`quic` or `net_quic`) availability
  - **Enhanced System Capabilities API**: `/api/capabilities` now reports detailed QUIC support status including:
    - Overall QUIC support status
    - Kernel module availability
    - Samba version and sufficiency
    - Detailed unsupported reason when unavailable
  - **Smart UI Integration**: Settings page switch with:
    - Automatic disable when requirements not met
    - Tooltip showing specific missing requirements
    - Warning message explaining why QUIC is unavailable
  - **Automatic Samba Configuration**: When enabled, applies mandatory encryption, port 443, and disables Unix extensions
  - **Comprehensive Documentation**: Detailed troubleshooting for Samba upgrades and kernel module loading
- **Auto-Update Service**: Implemented a backend service for automatic updates from GitHub releases, with support for multiple channels and local development builds.
- **Telemetry Configuration**: Added UI in Settings to configure telemetry modes, dependent on internet connectivity.
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
- Manage `local master` option (?)
- Add Rollbar telemetry service for error tracking and monitoring
- Help screen or overlay help/tour [#82](https://github.com/dianlight/srat/issues/82)
- Smart Control [#100](https://github.com/dianlight/srat/issues/100)
- HDD Spin down [#101](https://github.com/dianlight/srat/issues/101)

#### 🐛 Bug Fixes

- **Mount Creation and Update Retry Logic [#221](https://github.com/dianlight/srat/issues/221)**: Fixed "Error creating mount from ha_supervisor: 400" when systemd unit already exists or has a fragment file. The supervisor service now automatically attempts to remove stale mounts and retry creation/update when encountering a 400 error. Extended fix includes:
  - Retry logic for both create and update operations
  - Comprehensive test coverage for all edge cases
  - Handles stale systemd units in all mount scenarios
  - See `/docs/ISSUE_221_ANALYSIS.md` for detailed analysis

- `enable`/`disable` share functionality is not working as expected.
- Renaming the admin user does not correctly create the new user or rename the existing one; issues persist until a full addon reboot.
- Fix dianlight/hassio-addons#448 [SambaNAS2] Unable to create share for mounted volume
- Fix dianlight/hassio-addons#447 [SambaNAS2] Unable to mount external drive
- **Disk Stats Service**: Changed log level from `Error` to `Warn` for disk stats update failures to reduce log noise and better distinguish between critical errors and warnings
- **SQLite concurrency lock (SQLITE_BUSY) resolved [#164](https://github.com/dianlight/srat/issues/164)**: Hardened database configuration to prevent intermittent "database is locked" errors when reading mount points under concurrent load. Changes include enabling WAL mode, setting `busy_timeout=5000ms`, using `synchronous=NORMAL`, and constraining the connection pool to a single open/idle connection. Added repository-level RWMutex guards and a concurrency stress test.
- Addon protected mode check [#85](https://github.com/dianlight/srat/issues/85)

#### 🏗 Chore

- **Dependency Cleanup [#16](https://github.com/dianlight/srat/issues/16)**: Removed abandoned `github.com/m1/go-generate-password` dependency (last updated April 2022) and replaced with custom implementation using Go's standard `crypto/rand` library. The new `GenerateSecurePassword()` function provides cryptographically secure random passwords with no external dependencies.
- Implement watchdog
- Replace snapd osutil dependency with internal mount utilities based on moby/sys/mountinfo <!-- cspell:disable-line -->
- Align UI elements to HA [#81](https://github.com/dianlight/srat/issues/81)
- Create the base documentation [#80](https://github.com/dianlight/srat/issues/80)
- Display version from ADDON

##### **🚧 Work in progress**

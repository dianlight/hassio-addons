# Changelog

## 2025.12.0-dev [ 🚧 Unreleased ]

### 🙏 Thanks

- Thanks to all the contributors and users that help to make this addon better.
- Special thanks to supportes and soponsors. With our support I was able to buy a copilot subscription to help me code faster and better.

### 🚨 Notes
- This has been a big refactor to make the addon more efficient and use less resources. Some features have been removed or changed to improve stability and performance. Some will be added back in future releases.
- ***Your existing configuration will be lost when updating to this version. Please backup your configuration before updating.***
- ***If you need SMART capabilities or HDIdle support don't update and wait next releases.***

#### 💥 Breaking Changes
- Remove support to armv7 architecture
- Remove HDIdle support (for now is added back in future releases)
- Remove SMART capabilities (for now is added back in future releases)
- Remove Avahi/mDNS support (due to side effects on some systems)
- Remove WSDD support (due to instability)

###  ✨ Features
- Brand New icon and logo AI Generated
- New option `srat_update_channel`to manage SRAT Update (EXPERIMENTAL [DOCS](DOCS.md) )
- New UI (SRAT) to read and control the addon. (See [SRAT Repository](https://github.com/dianlight/srat) )
- ~~Announce Samba service via Avahi/mDNS for better discovery~~ Remove for side effects
- Support ~~WSDD and WSDD2~~ Wsdd-native for better Windows Discovery (Remove WSDD due to instability)
- Automatic modprobe for all kernel fs
- Add ability to use Custom Samba Version - Custom Build Only 

### 🏗 Chore
- Fork SambaNas to the new SambaNas2 addon
- New version model based on year.month.patch
- Samba to 4.23.1 compatibility 
- Update base image to latest Home Assistant base image 19.0.0
- Update the documentation
- Refactor the code to use less resources and be more efficient
- Improve the logging system 


### 🐭 Features from SRAT [v2025.12.0-dev.6](https://github.com/dianlight/srat)

#### 🙏 Thanks

We would like to thank all supporters for their contributions and donations!
With your donations, we are able to continue developing and improving this project. Your support is greatly appreciated!

#### 🧑‍🏫 Documentation

#### 🐛 Bug Fixes

- **Udev Event Parsing Error Handling**: Improved handling of malformed udev events to prevent spurious error reports to Rollbar. Malformed events with invalid environment data are now logged at debug level instead of error level, reducing noise in error tracking while maintaining visibility for legitimate errors.

#### 🔄 Breaking Changes

- **SMB over QUIC Default Behavior Change**: The SMB over QUIC feature is now disabled by default. Users must explicitly enable it in the settings to use this functionality. This change aims to enhance security and stability by preventing unintended use of the experimental protocol.
- **Telemetry Service Update**: The telemetry service has been updated to use Rollbar for error tracking and monitoring. This change may require users to review their privacy settings and consent to data collection, as Rollbar collects different types of data compared to the previous telemetry solution.
- **Auto-Update Service Modification**: The auto-update service has been modified to support multiple update channels (stable, beta, dev) and local development builds. Users may need to reconfigure their update preferences to align with the new channel system.

#### 🔧 Maintenance

- Updated dependencies to latest versions to ensure security and compatibility.

#### ✨ Features

- **Enhanced SMART Service [#234](https://github.com/dianlight/srat/issues/234)**: Implemented comprehensive SMART disk monitoring and control features:
- **SMB over QUIC Support [#227](https://github.com/dianlight/srat/issues/227)**: Added comprehensive support for SMB over QUIC transport protocol with intelligent system detection
- **Auto-Update Service**: Implemented a backend service for automatic updates from GitHub releases, with support for multiple channels and local development builds.
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

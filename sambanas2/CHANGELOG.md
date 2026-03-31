# Changelog

## 2026.3.0-rc [ 🚧 Unreleased ]

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

### 🐭 Features from SRAT [ 🚧 Unreleased ]

[docs]: https://github.com/dianlight/hassio-addons/blob/master/sambanas2/DOCS.md

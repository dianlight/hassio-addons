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
- Support ~~WSDD~~ and WSDD2
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


### 🐭 Features from SRAT [ 🚧 Unreleased ]


[docs]: https://github.com/dianlight/hassio-addons/blob/master/sambanas2/DOCS.md

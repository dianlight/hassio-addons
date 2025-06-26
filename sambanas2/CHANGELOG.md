# Changelog

## 2025.6.0-dev [ 🚧 Unreleased ]

###  ✨ Features
- Brand New icon and logo AI Generated
- New option `srat_update_channel`to manage SRAT Update (EXPERIMENTAL [DOCS](DOCS.md) )
- New UI (SRAT) to read and control the addon. (See [SRAT Repository](https://github.com/dianlight/srat) )
- Announce Samba service via Avahi/mDNS for better discovery
- Support ~~WSDD~~ and WSDD2
#### __🚧 Work in progess__
- [ ] ACL For folders [#208](https://github.com/dianlight/hassio-addons/issues/208)
- [ ] Migrate config from SambaNas addon
- [ ] Mobile ready UI

### 🏗 Chore
- Fork SambaNas to the new SambaNas2 addon
- New version model
#### __🚧 Work in progess__
- [ ] Update the documentation
    - [ ] Tutorial screenshots?
- [ ] En translation 

### 🐭 Features from SRAT [v2025.6.9-dev.8](https://github.com/dianlight/srat)

####  ✨ Features
- [X] Manage `recycle bin`option for share
- [X] Manage WSDD2 service
- [X] Manage Avahi service
- [X] Veto files for share not global [#79](https://github.com/dianlight/srat/issues/79)
####### __🚧 Work in progess__
- [ ] Manage `local master`option (?)
- [ ] Monitor tab (?)
- [ ] Help screen or overlay help/tour [#82](https://github.com/dianlight/srat/issues/82)
- [ ] Custom component [#83](https://github.com/dianlight/srat/issues/83)
- [ ] Ingress security validation [#89](https://github.com/dianlight/srat/issues/89)

####  🐛 Bug Fixes
- [X] `enable`/`disable` share functionality is not working as expected.
- [X] Renaming the admin user does not correctly create the new user or rename the existing one; issues persist until a full addon reboot.
####### __🚧 Work in progess__
- [ ]  [#80](https://github.com/dianlight/srat/issues/85)


#### 🏗 Chore
- [X] Implemet wachdog
####### __🚧 Work in progess__
- [ ] Create the base documentation [#80](https://github.com/dianlight/srat/issues/80)
- [ ] Display version from ADDON
- [ ] Align UI elements to HA [#81](https://github.com/dianlight/srat/issues/81)

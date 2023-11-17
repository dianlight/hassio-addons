# Changelog

## 12.1.0-nas

### 🏗 Chore

- [Full Changelog from official addon 12.1.0][changelog_12.1.0]
  - Use the new Home Assistant folder for the config share
  - Add support for accessing public add-on configurations
- [Full Changelog from official addon 12.0.0][changelog_12.0.0]
  - Adjust location of Home Assistant config to match latest dev/beta Supervisor
- [Full Changelog from official addon 11.0.0][changelog_11.0.0]
  - Add support for accessing public add-on configurations
  - Update Based Image to 14.3.2 (Alpine 3.18.4)
  - Adds HEALTCHECK support
- [Full Changelog from official addon 10.0.2][changelog_10.0.2]
  - Already Implemented: Enable IPv6 ULA and IPv4 link-local addresses by default

[changelog_12.1.0]: https://github.com/home-assistant/addons/pull/3312
[changelog_12.0.0]: https://github.com/home-assistant/addons/pull/3311
[changelog_11.1.0]: https://github.com/home-assistant/addons/pull/3001
[changelog_11.0.0]: https://github.com/home-assistant/addons/pull/3297
[changelog_10.0.2]: https://github.com/home-assistant/addons/pull/3062
[changelog_10.0.1]: https://github.com/home-assistant/addons/pull/2997

###  🩹 BugFix
- Fix mount concurrency. Solve some issue on addon-restart. (try to resolve [#159](https://github.com/dianlight/hassio-addons/issues/159))

###  ✨ Features
- Based Image 14.1.0 (Alpine 3.18.3)
- Added recycle bin option option default is set to 'false' [cherry pick from PR#167] ([DOCS.md][docs])
- Added mount options default is set to 'nosuid,relatime,noexec' [cherry pick from PR#167] ([DOCS.md][docs])
- Added filter for reserved sharenames (config addons ssl share backup media) [cherry pick from PR#167] 


## 10.0.2-nas4
###  🩹 BugFix
- Fix mount bug for ha 2023.7.x without acl config.

## 10.0.2-nas3

### ✨ Features
- Add support of `acl.usage` to specify what scope of disk is, usefull for network storage mount in ha ([DOCS.md][docs])

###  🩹 BugFix
- Always add docker network to whitelist - Try fix  [#157](https://github.com/dianlight/hassio-addons/issues/157)
- Correct cifs mount precedence. Try fix [[#159](https://github.com/dianlight/hassio-addons/issues/159)]

### 💥 BREAKING CHANGE
- Default `acl.timemachine` option now is set to `true`

## 10.0.2-nas2
### ✨ Features
- Read only users [[#141](https://github.com/dianlight/hassio-addons/issues/141)]
### 🩹 BugFix
- Fix Bug [[#154](https://github.com/dianlight/hassio-addons/issues/154)]
- Fix Bug [[#155](https://github.com/dianlight/hassio-addons/issues/155)]

## 10.0.2-nas1

### 🩹 BugFix

- Fix a regression on MQTT status publish [#151](https://github.com/dianlight/hassio-addons/issues/151)

## 10.0.2-nas

### ✨ Features

- Suport new network disk mount to allow share to be visible by other addons ([DOCS.md][docs])
- Dynamic frequency for updating disk sensor data. Minimizes CPU usage when disks are not in use.
- Based Image 14.0.1 (Alpine 3.18)
- Enable IPv6 ULA and IPv4 link-local addresses by default (from Samba Addon 10.0.2) [3062](https://github.com/home-assistant/addons/pull/3062)

### 🩹 BugFix

- Partial Fix about MQTT cpu usage [#134](https://github.com/dianlight/hassio-addons/issues/134)

### 💥 BREAKING CHANGE

- Host Mount was **DEPRECATED** (DEPRECATED [DOCS.md][docs])
- Minimal Homeassitant core supported version is now **2023.06.0**
- The default behavior has been changed. Now the disk sensor integration is no longer turned on by default but turned off. See [DOCS.md][docs]

## 10.0.0-nas8

### ✨ Features

- Not OperatinSystem Allert (force EXIT)
- Better support for "No Potection Mode"
  - [MQTT] support protected mode
- [MQTT] Add Disk device
  - [MQTT] Add HD Temperature information
  - [MQTT] Report SMART Status (Read Error Rate, Reallocate Sectorer.... )
  - [MQTT] Corret Device->Partition "via_device"
  - Update documentation
- Add option to enable SMART on supported drivers See [DOCS.md][docs]
- Add [hd-idle](https://github.com/adelolmo/hd-idle) support FR [#34](https://github.com/dianlight/hassio-addons/issues/34)

### 🩹 BugFix

- [MQTT] Fix issue about % in fsuse_pct [#126](https://github.com/dianlight/hassio-addons/issues/126)]

### 💥 BREAKING CHANGE

- The addon now go in error if no `Home Assistant OS` is found on host. See [DOCS.md][docs]

## 10.0.0-nas7

### 🩹 BugFix

- Fix issue about mount by id [#123](https://github.com/dianlight/hassio-addons/issues/123)
- Fix issue about automount without external scripts [#124](https://github.com/dianlight/hassio-addons/issues/124)
- Fix issue about mount hassos internal disks [#124](https://github.com/dianlight/hassio-addons/issues/124)

## 10.0.0-nas6

### 🩹 BugFix

- Fix issue about missing ntfs3 module on amd64 architecture [#121](https://github.com/dianlight/hassio-addons/issues/121)
- Fix missing libcap for wsdd2

### ✨ Features

- Add support for btrfs fs
- Add support for xfs fs

## 10.0.0-nas5

### 💥 BREAKING CHANGE 🆘

- Disk referenced by `id` that have a valid label are mounted and shared with label name.
- The automount feature is enabled by default. See [DOCS.md][docs]
- Backport [nas4]: Remove FUSE ntfs3g and exFat support (was broken so no one will use!).
- MQTT status message was refactored and report also fstype and disk iostat. If you need the old system use `mqtt_use_legacy_entities` option [DOCS.md][docs]
- New default config with automount and new mqtt entity system

### ✨ Features

- Disk and Partitions referenced by `id` now are mounted and shared by label name if exists **dedupl not work**
- Disk labels with ::space:: are now supported
- Disk summary with share names
- Backport [nas4]: Add support for NTFS3 fs 🎉 🎉 🚨🎉 🎉 (EXPERIMENTAL [DOCS.md][docs])) 🎉 🎉 🎉
- Backport [nas4]: Add support for exFat fs 🎉 🎉 🚨🎉 🎉 (EXPERIMENTAL [DOCS.md][docs])) 🎉 🎉 🎉
- Backport [nas4]: Add new MQTT report entity system based on device not on mount path and iostat [DOCS.md][docs]
- Backport [nas4]: Add Automount support for all partition's with labels [DOCS.md][docs]
- Backport [nas4]: Support Partition with spaces ISSUE [#118](https://github.com/dianlight/hassio-addons/issues/118)

### 🏗 Chore

- Backport [nas4]: Migrate to [Home Assistant Community Add-on: Base Images](https://github.com/hassio-addons/addon-base) 13.0.0
- Backport [nas4]: Migrate to new s6-rc system

### 🩹 BugFix

- Backport [nas4]: Fix error without MQTT server BUG [#116](https://github.com/dianlight/hassio-addons/issues/116)

## 10.0.0-nas4 [Restricted release]

### ✨ Features

- Add support for NTFS3 fs 🎉 🎉 🚨🎉 🎉 (EXPERIMENTAL [DOCS.md][docs])) 🎉 🎉 🎉
- Add support for exFat fs 🎉 🎉 🚨🎉 🎉 (EXPERIMENTAL [DOCS.md][docs])) 🎉 🎉 🎉
- Add new MQTT report entity system based on device not on mount path and iostat [DOCS.md][docs]
- Add Automount support for all partition's with labels [DOCS.md][docs]
- Support Partition with spaces ISSUE [#118](https://github.com/dianlight/hassio-addons/issues/118)

### 🏗 Chore

- Migrate to [Home Assistant Community Add-on: Base Images](https://github.com/hassio-addons/addon-base) 13.0.0
- Migrate to new s6-rc system

### 🩹 BugFix

- Fix error without MQTT server BUG [#116](https://github.com/dianlight/hassio-addons/issues/116)

### 💥 BREAKING CHANGE

- The automount feature is enabled by default. See [DOCS.md][docs]
- Remove FUSE ntfs3g and exFat support (was broken so no one will use!).
- MQTT status message was refactored and report also fstype and disk iostat. If you need the old system use `mqtt_use_legacy_entities` option [DOCS.md][docs]
- New default config with automount and new mqtt entity system

## 10.0.0-nas3

### ✨ Features

- Add `loglevel` option.

### 🩹 BugFix

- Fix Share Name BUG [#106](https://github.com/dianlight/hassio-addons/issues/106)

### 💥 BREAKING CHANGE

There is a new algorithm for creating the SHARE name. Therefore the name of the exposed shares could change.

## 10.0.0-nas2

### 🩹 BugFix

- Fix ACL Bug [#98](https://github.com/dianlight/hassio-addons/issues/98)

## 10.0.0-nas1

### 🩹 BugFix

- Fix Host Unmountig Bug [#94](https://github.com/dianlight/hassio-addons/issues/94)

## 10.0.0-nas

### 💥 BREAKING CHANGE

- Don't mangle filenames: By default, Samba mangles filenames with special characters to ensure
  compatibility with really old versions of Windows which have a very limited charset for filenames. The add-on no longer does this as modern operating
  systems do not have these restrictions.

### ✨ Features

- Option to use WSDD2 over WSDD (see [DOCS.md][docs])

### 🏗 Chore

- Refactor all MQTT HA integration
- Refactor root mount point selection ( no more pollution in /media if you don't use medialibrary )
- Refactor Docker composition
- [Full Changelog from official addon 10.0.0][changelog_10.0.0]
  - Don't mangle filenames (fixes [#2541](https://github.com/home-assistant/addons/issues/2541))

[changelog_10.0.0]: https://github.com/home-assistant/addons/pull/2545

### 🩹 BugFix

- Autodiscovery (WSDD2) interface respect configuration

## 9.7.0-nas2

### 🩹 BugFix

- Merged PR #85 by @grischard - Fix Bug [#84](https://github.com/dianlight/hassio-addons/issues/84)

## 9.7.0-nas1

### ✨ Features

- Add wsdd for Windows10/11 autodiscovery
- Support Enabline/Disabling Shares (based on PR#72 by @Uneo7 | Issue #24)
- Support for different users on shares (Issue #19)
- Interface options ( based on the idea of lmagyar/homeassistant-addon-samba-interface addon )

### 🏗 Chore

- Upgrade Alpine Linux to 3.16

### 🩹 BugFix

- AVAHI Support hostname with dot

## 9.7.0-nas

### ✨ Features

- Add btrfs support (PR #75 By @fAuernigg)

### 🩹 BugFix

- Change startup to system (PR #81 By @marciogranzotto)

### 🏗 Chore

- [Full Changelog from official addon 9.5.1][changelog_9.7.0]
  - Upgrade Alpine Linux to 3.15
  - Sign add-on with Codenotary Community Attestation Service (CAS)
- [Full Changelog from official addon 9.5.0][changelog_9.6.1]
  - Remove lo from interface list
  - Exit with error if there are no supported interfaces to run Samba on
- [Full Changelog from official addon 9.6.0][changelog_9.6.0]
  - Run on all supported interfaces

[changelog_9.7.0]: https://github.com/home-assistant/addons/pull/2070
[changelog_9.6.1]: https://github.com/home-assistant/addons/pull/2031
[changelog_9.6.0]: https://github.com/home-assistant/addons/pull/2023

## 9.5.1-nas4

### ✨ Features

- Lovely initial Banner!
- New Option `available_disks_log` to turn on/off the list of available Labeled disk in log

### 🩹 BugFix

- Fixed Bug #60 ( No access after update to Samba NAS 9.5.1-nas3 )

## 9.5.1-nas3

### ✨ Features

- List all available Labeled and Id disks on startup. Useful for configuration
- Support mount by disk Id as label (Format `id:<diskid>`)

### 🩹 BugFix

- Fixed Bug #58 ( Latest update doesn't allow multiple mounts )

## 9.5.1-nas2

### 🩹 BugFix

- Fixed Bug #54 ( MQTT Available missing for some disks )

## 9.5.1-nas1

### ✨ Features

- 🎉 🎉 🚨🎉 🎉 Support to Host Mount (EXPERIMENTAL [DOCS.md][docs])) 🎉 🎉 🎉

### 🏗 Chore

- Remove Private Key from log

## 9.5.1-nas

### ✨ Features

- 🎉 🎉 🚨🎉 🎉 Support to Host Mount (EXPERIMENTAL [DOCS.md][docs]) 🎉 🎉 🎉

### 📚 Documentation

- Correct and update DOCS.md

### 🏗 Chore

- [Full Changelog from official addon 9.5.1][changelog_9.5.1]
- [Full Changelog from official addon 9.5.0][changelog_9.5.0]
- [Full Changelog from official addon 9.4.0][changelog_9.4.0]
- Update options schema for passwords (Official Addon 9.3.1)

[changelog_9.5.1]: https://github.com/home-assistant/addons/pull/2070
[changelog_9.5.0]: https://github.com/home-assistant/addons/pull/2031
[changelog_9.4.0]: https://github.com/home-assistant/addons/pull/2023
[changelog_9.3.1]: https://github.com/home-assistant/hassio-addons/pull/1569

## 9.3.0-nas8

- chore: Support new Supervisor/Hardware ( remov dev\_ trick )
- chore: Apparmor config optimization for broadcast.
- fix: remove double % sign on HA report. (Bug #38)

## 9.3.0-nas7

- Fix: config style for new Supervisor/Hardware
- Added Apparmor config (PR #36 by @alexbelgium) (Bug #35)

## 9.3.0-nas6

- Fix: Ignore MQTT service if the given HA url is invalid.

## 9.3.0-nas5

- Disable MQTT integration in no MQTT service is found

## 9.3.0-nas4

- Remove unnecessary devicetree request (Bug #13)

## 9.3.0-nas3

- Fix idmap range not specified warning in log
- MQTT sensor improvement:
  - Option to disable MQTT integration
  - Options to control MQTT autodiscovery
  - Added device data to HA discovery messages
  - Better Device\Sensors tree
  - Autoremove discovery on disk unmount
  - Fix MQTT unique_id to allow HA interface management

## 9.3.0-nas2

- Fix autobuild script for empty directories
- Removed unused debug.

## 9.3.0-nas1

- Bugfixes
- Expose NAS disk status on MQTT (60s refresh)
- Update Samba to 4.12.7

## 9.3.0-nas

- [Full Changelog from official addon][changelog_9.3.0]
- Support new media folder
- Update Samba to 4.12.6
- Upgrade Alpine Linux to 3.12

[changelog_9.3.0]: https://github.com/home-assistant/hassio-addons/pull/1569

## 9.2.0-nas

- [Based on samba addon 9.2.0]
- Pin base image version
- Rewrite add-on onto S6 Overlay
- Use default configuration location
- Add support for running in compatibility mode (SMB1/NT1)
- Add dummy files to reduce number of errors/warnings in log output
- Allow IPv6 link-local hosts by default, consistent with IPv4

## 9.0-nas

### Added

- Add devfs support
- Add Time Machine support ( share disk can be used for Time Machine backup )
- Add disk/by-label automount and autoshare
- Add mDNS service registration

### Security

- Elevated minimal supported protocol to SMB2

### Changed

- [Based on samba addon 9.0](https://github.com/home-assistant/hassio-addons/tree/master/samba)

## 9.0

- New option `veto_files` to limit writing of specified files to the share

## 8.3

- Fixes a bug in warning log message, causing start failure
- Minor code cleanups

## 8.2

- Update from bash to bashio

## 8.1

- Update Samba to version 4.8.8

## 8.0

- Fix access to /backup

## 7.0

- Remove guest access
- Cleanup structure
- Use hostname for samba device name

## 6.0

- Enable ntlm auth for Windows10

## 5.0

- Update Samba to version 4.8.4

## 4.1

- Bugfix sed command

## 4.0

- New option `allow_hosts` to limit access

## 3.0

- Update base image

[docs]: https://github.com/dianlight/hassio-addons/blob/master/sambanas/DOCS.md

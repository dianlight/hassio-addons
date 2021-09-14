# Changelog

## 9.5.1-nas2

### 🩹 BugFix

- Fixed Bug #54 ( MQTT Available missing for some disks )

## 9.5.1-nas1

### ✨ Features 

- 🎉 🎉 🚨🎉 🎉  Support to Host Mount (EXPERIMENTAL [DOCS.md](https://github.com/dianlight/hassio-addons/blob/master/sambanas/DOCS.md)) 🎉 🎉 🎉 

### 🏗 Chore

- Remove Private Key from log 

## 9.5.1-nas

### ✨ Features 

- 🎉 🎉 🚨🎉 🎉  Support to Host Mount (EXPERIMENTAL [DOCS.md](https://github.com/dianlight/hassio-addons/blob/master/sambanas/DOCS.md)) 🎉 🎉 🎉 

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

- chore: Support new Supervisor/Hardware ( remov dev_ trick )
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

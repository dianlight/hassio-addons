# Changelog

## 9.3.0-nas1
- Bugfixes
- Expose NAS disk status on MQTT (60s refresh)

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

## [9.0-nas] - 2020-02-14

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
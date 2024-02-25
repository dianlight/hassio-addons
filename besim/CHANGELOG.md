# Changelog

## 0.0.3

###  ✨ Features
- New `zone_entity` options to pass latitude and LATITUDE e LONGITUDE.
- Collect usage statistics for control API usage
- WebGui
  - Ingress Mode TODO:
  - Show statistics TODO:
  - Control SmartBox and Thermostat TODO:
  - Show OT status and values TODO:

### 📚 Documentation
- Integration diagram TODO:
- DNS Configuration diagram TODO:
  - AdGuard Home config example TODO:
  - DNSMasq config example TODO:
- Mobile APPS TODO:
  - Changelog / Support TODO:
  - Android App TODO:
    - Unpin certificate TODO:
    - Change from HTTPS to HTTP TODO:
    - MegaDownload apk petched TODO:

## 0.0.2 [Unreleased]

<!--
### 💥 BREAKING CHANGE
- ...
-->

###  ✨ Features
- New `updateonboot` that update [BeSIM-MQTT] component to the last commit at startup.
- New `work_as_proxy` that configure the [BeSIM-MQTT] component to work as proxy using DNS as upstream
- New `upstream_dns` that configure the upstream DNS for [BeSIM-MQTT] component

###  🩹 BugFix
- 🐛 Fix double start without control

### 🏗 Chore

- [BeSIM-MQTT]: Update to the last Snapshot [8ef1249f08a3688b0d6813551e1b3688102ba349]


## 0.0.1 [Unreleased]

###  ✨ Features
- Addon creation! 🤡



[BeSIM-MQTT]: https://github.com/dianlight/BeSIM-MQTT
[DOC]: ./DOCS.md
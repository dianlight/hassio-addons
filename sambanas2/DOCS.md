# Home Assistant Add-on: Samba NAS2 ![Logo](docs/full_logo.png)

## 🚨 Important Note 🚨

This addon has been designed, built and tested to work with HAOS (Homeassistant Operating System). The use in other types of installations is not recommended and useless as other solutions given by the host can be used.

## Feature Comparison: SambaNAS vs SambaNAS2

### Introduction

SambaNAS2 is a newly released successor to the original SambaNAS add-on. Please note that SambaNAS2 is still under active development and does not yet provide all the features available in the original SambaNAS. Some advanced functionalities will be introduced in future versions as the project continues to evolve.

The following table compares the major functionalities available in SambaNAS and SambaNAS2:

| Functionality                     | SambaNAS | SambaNAS2 |
|------------------------------------|:--------:|:---------:|
| CIFS Volume Exporting              |    ✔️     |    ✔️      |
| NFS Volume Exporting               |    ❌     |  🚧 Soon   |
| Mounting additional volumes        |    ✔️     |    ✔️      |
| Enhanced mount flags management    |    ❌     |    ✔️      |
| Umounting volumes                  |    ❌     |    ✔️      |
| Hotplug device events              |    ❌     |    ✔️      |
| User Management                    |    ✔️     |    ✔️      |
| User HA Integration                |    ❌     |  🚧 Soon   |
| Advanced Share Permissions         |    ❌     |  🚧 Soon   |
| Recycle Bin Support                |    ❌     |    ✔️      |
| Web UI for Management              |    ❌     |    ✔️      |
| Enhanced Logging                   |    ❌     |    ✔️      |
| SMB Multichannel Support           |    ✔️     |    ✔️      |
| Regular Updates                    |  🔚 EOL   |    ✔️      |
| MQTT integration                   |    ✔️     |    ❌      |
| HA Native API Integration          |    ❌     |    ✔️      |
| Component Integration              |    ❌     |  🚧 Soon   |
| WSDD and WSDD2 Integration         |    ✔️     |    ✔️ wsdd2 only      |
| Watchdog                           |    ✔️     |    ✔️   |

> ✔️ = Supported  ❌ = Not Supported  🚧 Soon = Coming in future versions  🔚 EOL = End of Life

## Installation

**Requirements:**
- Home Assistant 2025.8.0 or newer
- Home Assistant Operating System (HAOS) - recommended and tested platform
- Supported architectures: armv7, aarch64, amd64

Follow these steps to get the add-on installed on your system:

1. Navigate in your Home Assistant frontend to **Supervisor** -> **Add-on Store**.
2. Find the "Samba NAS2" add-on and click it.
3. Click on the "INSTALL" button.
4. Turn on "Show in sidebar" option
5. Turn off "Protection mode" option
6. In the configuration section, set a username and password.
7. Click on the "START" button. 
8. Wait until the addon start
9. Click "Samba NAS 2" on your sidebar

## How to use

1. In the configuration section, set a username and password.
2. Review the enabled shares. Disable any you do not plan to use. Shares can be re-enabled later if needed.

## Web Interface

Samba NAS2 includes an integrated web interface for management and configuration. You can access it in two ways:

1. **Through Home Assistant Ingress** (Recommended): Click "Samba NAS 2" in your Home Assistant sidebar. This provides seamless integration within your Home Assistant interface.

2. **Direct Access**: If you need to access the interface outside of Home Assistant, you can connect directly using `http://<HOME_ASSISTANT_IP>:3000`. Note that this port is not exposed by default and may require additional configuration.

The web interface provides access to SRAT (Samba REST Administration Tool), which offers a user-friendly way to configure and manage your Samba shares, users, and settings.

## Connection

If you are on Windows you use `\\<IP_ADDRESS>\`, if you are on MacOS you use `smb://<IP_ADDRESS>` to connect to the shares.

This addon exposes the following directories over smb (samba):

| Directory       | Description                                                              |
| --------------- | ------------------------------------------------------------------------ |
| `addons`        | This is for your local add-ons.                                          |
| `backup`        | This is for your snapshots.                                              |
| `config`        | This is for your Home Assistant configuration.                           |
| `addon_configs` | This is for your Addons base configuration directory                     |
| `media`         | This is for local media files.                                           |
| `share`         | This is for your data that is shared between add-ons and Home Assistant. |
| `ssl`           | This is for your SSL certificates.                                       |

## Configuration

This is an example of a configuration with all available options and their default values:

```yaml
srat_update_channel: none
enable_smart: true
hdd_idle_seconds: 30
log_level: warning
leave_front_door_open: false
```

**Note**: All configuration options are optional. You only need to specify options where you want to change the default value.

### Option: `log_level` (optional)

The log_level option controls the level of log output by the addon and can be changed to be more or less verbose, which might be useful when you are dealing with an unknown issue. Possible values are:

- trace: Show every detail, like all called internal functions.
- debug: Shows detailed debug information.
- info: Normal (usually) interesting events.
- warning: Exceptional occurrences that are not errors.
- error: Runtime errors that do not require immediate action.
- fatal: Something went terribly wrong. Add-on becomes unusable.

Please note that each level automatically includes log messages from a more severe level, e.g., debug also shows info messages. By default, the log_level is set to info, which is the recommended setting unless you are troubleshooting.

### Option: `hdd_idle_seconds` (optional) (**Use only if your disks never spind down**)

Idle time in seconds for all disks. Setting this value to 0 will never spin down the disk(s).

**NOTE<sup>1</sup>**: Depending on your environment host system can take up to **10minutes** to unlock used file on disk so setting to a low number like 10 don't garantee that the disk go on sleep after 10s from last access. Sometime you need to wait 10 or 15 minutes.
**NOTE<sup>2</sup>**: If you use `mqtt_nexgen_entities` also enable a new sensor for power disk status.

Defaults to hd-idle demon not being used at all.

### Option: `enable_smart` (optional)

Enable SMART on all disks, enable automatic offline testing every four hours, and enable autosaving of SMART Attributes.

Defaults to `true`.

### Options `srat_update_channel` (optional) **_Exteprimental_**

SRAT (Samba REST Administration Tool) is a new system designed to provide a simplified user interface for configuring SAMBA. It has been developed to work within Home Assistant, specifically for this addon, but can also be used in other contexts.

Currently under development and in an alpha state, SRAT is set to become the preferred system for configuring and using this addon, eventually "retiring" the YAML configuration.

Setting this option to `release`, `prerelease`, or `develop` turn on the auto update of srat ( Samba Rest Adminitration Tool )
on the choosed channel.

- `none`: No automatic updates (default)
- `release`: Stable releases only
- `prerelease`: Beta/pre-release versions
- `develop`: Development versions (experimental, use with caution, not available in release)

Defaults to `none`

### Option: `leave_front_door_open` (optional)

When enabled (set to `true`), this option allows guest access to the Samba shares without requiring authentication. This creates an open network share that can be accessed by anyone on the network without providing a username and password.

⚠️ **Security Warning**: Enabling this option significantly reduces security as it allows unrestricted access to your shared directories. Only enable this in trusted network environments where you want to provide easy access without authentication barriers.

Defaults to `false` (authentication required).

## Support

### Do you like the Addon?
<a href="https://www.buymeacoffee.com/ypKZ2I0"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=ypKZ2I0&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" /></a>

### Common problems


In case you've found a bug, please [open an issue on our GitHub][issue].

[issue]: https://github.com/dianlight/hassio-addons/issues
[reddit]: https://reddit.com/r/homeassistant
[repository]: https://github.com/dianlight/hassio-addons

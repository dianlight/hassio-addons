# Home Assistant Add-on: Samba NAS share

# 📰 Important Notice Regarding SambaNas Addon Development

**SambaNas Addon is Now in Maintenance Mode**

This notice is to inform our users that the **SambaNas addon will now transition into maintenance mode.** This means that **no future features will be implemented** for this version of the addon. Our development efforts will be focused solely on providing **critical bug fixes** to ensure its continued stability for existing users.

**Introducing SambaNas2: The Future of Samba Integration**

We are excited to announce **SambaNas2**, the successor to the original SambaNas addon! SambaNas2 represents a **complete rewrite from the ground up, developed in Go with a brand new core.** This will bring significant improvements in performance, stability, and future extensibility.

**Current Status and Upcoming Beta Release**

SambaNas2 is currently in an **Alpha stage** of development. We are pleased to announce that a **public Beta version will be released in the coming weeks** and will be available through our beta channel.

We encourage users interested in the latest features and improvements to keep an eye out for the SambaNas2 beta release. Thank you for your continued support.


## 🚨 Important Note 🚨

This addon has been designed, built and tested to work with HAOS (Homeassistant Operating System). The use in other types of installations is not recommended and useless as other solutions given by the host can be used.

### Using it on a different operating system leads to the error at startup. I apologize to all the advanced users who are using it on different OSes but I manage the addon in my spare time and instead of doing something useful lately I'm only replying to people who don't read the documentation. "This is the meaning of life"

## Installation

Follow these steps to get the add-on installed on your system:

1. Navigate in your Home Assistant frontend to **Supervisor** -> **Add-on Store**.
2. Find the "Samba NAS share" add-on and click it.
3. Click on the "INSTALL" button.

## How to use

1. In the configuration section, set a username and password.
2. Review the enabled shares. Disable any you do not plan to use. Shares can be re-enabled later if needed.

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

This is an example of a configuration. **_DO NOT USE_** without making the necessary changes especially for the username, password, secret and moredisk part.
Fields between `<` and `>` indicate values that are omitted and need to be changed.

```yaml
workgroup: WORKGROUP
local_master: true
username: Hassio
password: "<Your secret password>"
allow_hosts:
  - 10.0.0.0/8
  - 172.16.0.0/12
  - 192.168.0.0/16
  - 169.254.0.0/16
  - fe80::/10
  - fc00::/7
automount: true
moredisks:
  - "<Partition's Label>"
  - "id:<Partition uuid>"
mountoptions: "nosuid,relatime,noexec"
veto_files:
  - "._*"
  - ".DS_Store"
  - Thumbs.db
compatibility_mode: false
recyle_bin_enabled: false
available_disks_log: true
wsdd: true
wsdd2: false
medialibrary:
  enable: true
other_users:
  - username: backupuser
    password: "<backupuser secret password>"
  - username: secureuser
    password: "<secureuser secret password>"
acl:
  - share: config
    disabled: true
  - share: backup
    disabled: false
    users:
      - backupuser
  - share: ssl
    users:
      - secureuser
```

### Option: `workgroup` (required)

Change WORKGROUP to reflect your network needs.

### Option: `local_master` (required)

Enable to try and become a local master browser on a subnet.

### Option: `username` (required)

The username you would like to use to authenticate with the Samba server.

### Option: `password` (required)

The password that goes with the username configured for authentication.

### Option: `allow_hosts` (required)

List of hosts/networks allowed to access the shared folders.

### Option `automount` (optional)

**_Protection Mode must be disabled to allow this function_**
Automatic mount and expose all labeled disk.

Defaults to `true`.

### Option: `moredisks` (optional)

**_Protection Mode must be disabled to allow this function_**
List of disks or partitions label to search and share. It is also possible to use the disk id if you prepend the name with `id:` (WARN: write id prefix in lowercase only!)

The following Fs are supported:

- [x] ext3
- [x] ext2
- [x] ext4
- [x] squashfs
- [x] vfat --> **_NOTE: ACL are not supported so no TimeMachine compatibility_**
- [x] msdos --> **_NOTE: ACL are not supported so no TimeMachine compatibility_**
- [x] f2fs --> **_NOTE: ACL are not supported so no TimeMachine compatibility_**
- [x] exFat --> **_NOTE: Experimental with exFat kernel driver_**
- [x] ntfs --> **_NOTE: Experimental with ntfs3 kernel driver. Not available on some architectures_**
- [x] brtfs
- [x] xfs
- [x] apfs --> **_NODE: Very Experimental. ReadOnly and referenced only by id not label. Mount options are not supported_**

### Option `mountoptions` (required)
Allows setting of mount options.

**_Protection Mode must be disabled to allow this function_**
Defaults to 'nosuid,relatime,noexec'

### Option `available_disks_log` (optional)

Enable the log of found labeled disk. Usefull for initial configuration.

### Option: `log_level` (optional)

The log_level option controls the level of log output by the addon and can be changed to be more or less verbose, which might be useful when you are dealing with an unknown issue. Possible values are:

- trace: Show every detail, like all called internal functions.
- debug: Shows detailed debug information.
- info: Normal (usually) interesting events.
- warning: Exceptional occurrences that are not errors.
- error: Runtime errors that do not require immediate action.
- fatal: Something went terribly wrong. Add-on becomes unusable.

Please note that each level automatically includes log messages from a more severe level, e.g., debug also shows info messages. By default, the log_level is set to info, which is the recommended setting unless you are troubleshooting.

### Option: `medialibrary` (optional) **_Exteprimental_**

Enable the visibility of `moredisk` on /media path.

_Starting from Homeassistant 2023.6.0 the addon use the 'mount' supervisor feature. So you don't need the ssh key anymore._

**WARNING: The feature is considered experimental and may cause problems or data loss.**

#### Option: `enable` (optional)

Enable/Disable host mounting option.

Defaults to `false`.

### Option: `recyle_bin_enabled` (optional)

Setting this option to `true` will enable recycle bin functions
on the Samba add-on. ***Check 'veto_files' as could be blocked by '._*'.***

Defaults to `false`.

#### Option: `ssh_private_key` (optional) **_Deprecated_**

The **_PRIVATE_** key for SSH access to the host on port 22222.

Enables mounting of `moredisk` by the host and not by the container.

NOTE<sup>1</sup>: It works only and only on HassOS on other hosts it is not tested and most likely it does not work.

NOTE<sup>2</sup>: It is necessary to enable the access to the SSH port 22222 of the host. Read the HassOS [Developers Documentation](https://developers.home-assistant.io/docs/operating-system/debugging/#home-assistant-operating-system) or use the [Configutarion Addon](https://community.home-assistant.io/t/add-on-hassos-ssh-port-22222-configurator/264109).

NOTE<sup>3</sup>: It is necessary to pass the SSH private key for root access to the host. Be sure to use secrets files to protect the key from people who don't have access to it.

NOTE<sup>4</sup>: If the disk in the "Media Browser" is seen empty try restarting Homeassitant.


### Option: `veto_files` (optional)

List of files that are neither visible nor accessible. Useful to stop clients
from littering the share with temporary hidden files
(e.g., macOS `.DS_Store` or Windows `Thumbs.db` files)

### Option: `other_users` (optional) (**advanced users only**)

The list of additional user for the addon. See `acl` option for enable the access to the shares.

#### Option: `username` (required)

The username you would like to use to authenticate with.

#### Option: `password` (required)

The password that goes with the username configured for authentication.

### Option: `acl` (optional) (**advanced users only**)

The Access Control List for shares. This is an advanced parameter to control every single share.
The format is an array of share object with this subparameters

#### Option: `share` (required)

The share name.

#### Option: `disabled` (optional)

If the disabled flag is true the share is not exported

Defaults to `false`

#### Option: `users` (optional)

The list of users with access to share. If omitted the main user is used. See `other_users` option

Defaults to `master user`

#### Option: `ro_users` (optional)

The list of users with readonly access to share.

Defaults to none

#### Option: `timemachine` (optional)

If is true the share is exposed with timechine compatible setting.

Defaults to `false` for internal share, `true` forn extra disks.

### Option: `usage` (optional) (**valid only for external disks**)

Set the scope of the disk, usefull for ha network storage mount. Valid values are `media`,`backup`,`share`

Defaults to `media` for external disks if `medialibray` is enabled.


### Option: `interfaces` (optional) (**advanced users only**)

The network interfaces Samba should listen on for incoming connections.

This option should only be used in advanced cases. In general, setting this option is not needed.

If omitted Samba will listen on all supported interfaces of Home Assistant (see > ha network info), but if there are no supported interfaces, Samba will exit with an error.

**Note**: Samba needs at least one non-loopback, non-ipv6, local interface to listen on and become browser on it. Without it, it works, but reloads it's interfaces in an infinite loop forever in each 10 seconds to check, whether a non-loopback, non-ipv6, local interface is added. This reload will fill the log file with infinite number of entries like added interface lo ip=::1 bcast= netmask=ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff.

### Option: `bind_all_interfaces` (optional)

Force Samba to bind on all network interface.
This is usefull for pseudo-ethernet devices like TailScale

Defaults to `false`.

### Option: `compatibility_mode` (optional)

Setting this option to `true` will enable old legacy Samba protocols
on the Samba add-on. This might solve issues with some clients that cannot
handle the newer protocols, however, it lowers security. Only use this
when you absolutely need it and understand the possible consequences.

Defaults to `false`.

### Option: `wsdd`

Setting this option to `true` will enable the use of wsdd over internal samba system.

Defaults to `true`.

### Option: `wsdd2` (optional) (**advanced users only**)

Setting this option to `true` will enable the use of wsdd2 over wsdd. Set to true if you have trouble to see the disk on Windows 11+

Defaults to `false`.

### Option: `hdd_idle_seconds` (optional) (**Use only if your disks never spind down**)

Idle time in seconds for all disks. Setting this value to 0 will never spin down the disk(s).

**NOTE<sup>1</sup>**: Depending on your environment host system can take up to **10minutes** to unlock used file on disk so setting to a low number like 10 don't garantee that the disk go on sleep after 10s from last access. Sometime you need to wait 10 or 15 minutes.
**NOTE<sup>2</sup>**: If you use `mqtt_nexgen_entities` also enable a new sensor for power disk status.

Defaults to hd-idle demon not being used at all.

### Option: `enable_smart` (optional)

Enable SMART on all disks, enable automatic offline testing every four hours, and enable autosaving of SMART Attributes.

Defaults to `true`.

### Option: `multi_channel` (optional) **_Exteprimental_**

Samba 4.4.0 adds *experimental* support for SMB3 Multi-Channel.
Multi-Channel is an SMB3 protocol feature that allows the client
to bind multiple transport connections into one authenticated
SMB session. This allows for increased fault tolerance and
throughput. The client chooses transport connections as reported
by the server and also chooses over which of the bound transport
connections to send traffic. I/O operations for a given file
handle can span multiple network connections this way.
An SMB multi-channel session will be valid as long as at least
one of its channels are up.

Defaults to `false`

### Option: `mqtt_enable` (optional)

Setting this option to `true` will enable the use of mqtt to send disks status data.

Defaults to `false`.

### Option: `mqtt_nexgen_entities` (optional)

Setting this option to `true` will expose mqtt new entities. This is a refactor that allow to use less CPU.

**NOTE<sup>1</sup>**: If your HDD newer spindown please set `hdd_idle_seconds`.


Defaults to `false`.

### Option: `mqtt_host` (optional)

If using an external mqtt broker, the hostname/URL of the broker. See [MQTT Status Notifications](https://github.com/thomasmauerer/hassio-addons/blob/master/samba-backup/DOCS.md#mqtt-status-notifications) for additional infos.

**Note**: _Do not set this option if you want to use the (on-device) Mosquitto broker addon._

### Option: `mqtt_username` (optional)

If using an external mqtt broker, the username to authenticate with the broker.

### Option: `mqtt_password` (optional)

If using an external mqtt broker, the password to authenticate with the broker.

### Option: `mqtt_port` (optional)

If using an external mqtt broker, the port of the broker. If not specified the default port 1883 will be used.

### Option: `mqtt_topic` (optional)

The topic to which status updates will be published. You can only control the root topic with this option, the subtopic is fixed!

_Example_: sambanas/status: "sambanas" is the root topic, whereas "status" is the subtopic.

### Option: `autodiscovery` (**advanced users only**)

#### Option: `disable_discovery` (optional)

Setting this option to `true` will disable the sending of Auto Discovery MQTT messages. You need to configure MQTT sensors manually

Defaults to `false`.

#### Option: `disable_persistent` (optional)

Setting this option to `true` will disable the mark MQTT discovery messages as persistents.

Defaults to `false`.

#### Option: `disable_autoremove` (optional)

Setting this option to `true` will disable the delete of MQTT discovery messages when addon stop.

Defaults to `false`.

## Support

### Do you like the Addon?
<a href="https://www.buymeacoffee.com/ypKZ2I0"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=ypKZ2I0&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" /></a>

### Common problems

- **_The disk does not mount_** : check that the Label of the partition of the disk you want to mount is case-sensitive with the label indicated in the `moredisk` parameter.

- **_In the menu `Media Browser` the folder with the name of the disk is empty_** : it happens when the homeassistant server starts before the add-on. Restart HomeAssitant from menu `Configuration->Server Controls->Server management -> RESTART`

In case you've found a bug, please [open an issue on our GitHub][issue].

[issue]: https://github.com/dianlight/hassio-addons/issues
[reddit]: https://reddit.com/r/homeassistant
[repository]: https://github.com/dianlight/hassio-addons

# Home Assistant Add-on: Samba NAS share

## Installation

Follow these steps to get the add-on installed on your system:

1. Navigate in your Home Assistant frontend to **Supervisor** -> **Add-on Store**.
2. Find the "Samba NAS share" add-on and click it.
3. Click on the "INSTALL" button.

## How to use

1. In the configuration section, set a username and password.
2. Save the configuration.
3. Start the add-on.
4. Check the add-on log output to see the result.

## Connection

If you are on Windows you use `\\<IP_ADDRESS>\`, if you are on MacOS you use `smb://<IP_ADDRESS>` to connect to the shares.

This addon exposes the following directories over smb (samba):

Directory | Description
-- | --
`addons` | This is for your local add-ons.
`backup` | This is for your snapshots.
`config` | This is for your Home Assistant configuration.
`media` | This is for local media files.
`share` | This is for your data that is shared between add-ons and Home Assistant.
`ssl` | This is for your SSL certificates.

## Configuration

This is an example of a configuration. ***DO NOT USE*** without making the necessary changes especially for the username, password, secret and moredisk part.
Fields between `<` and `>` indicate values that are omitted and need to be changed.

```yaml
workgroup: WORKGROUP
username: Hassio
password: '<Your secret password>'
allow_hosts:
  - 10.0.0.0/8
  - 172.16.0.0/12
  - 192.168.0.0/16
moredisks:
  - <DISKLABEL1>
  - <DISKLABEL2>
  - <id:DISKID1>
veto_files:
  - "._*"
  - ".DS_Store"
  - Thumbs.db
compatibility_mode: false  
medialibrary:
  enable: true
  ssh_private_key: |
    -----BEGIN RSA PRIVATE KEY-----
    <Your super secret private key in base64 form. As form .ssh/id_rsa file>
    -----END RSA PRIVATE KEY-----

```

### Option: `workgroup` (required)

Change WORKGROUP to reflect your network needs.

### Option: `username` (required)

The username you would like to use to authenticate with the Samba server.

### Option: `password` (required)

The password that goes with the username configured for authentication.

### Option: `allow_hosts` (required)

List of hosts/networks allowed to access the shared folders.

### Option: `moredisks` (optional)

***Protection Mode must be disabled to allow this function***
List of disks or partitions label to search and share. It is also possible to use the disk id if you prepend the name with `id:` (WARN: write id prefix in lowercase only!)
***NOTE: partitions label with spaces are NOT SUPPORTED***
The following Fs are supported:

- [X] ext3/4
- [X] fat --> ***NOTE: ACL are not supported so no TimeMachine compatibility***

Unsupported Fs:

- All Fuse based FS like exFat, fat32, ntfs. Samba don't like fuse.

### Oprion `available_disks_log` (optional)

Enable the log of found labeled disk. Usefull for initial configuration.

### Option: `medialibrary` (optional) ***Exteprimental***

Enables mounting of `moredisk` by the host and not by the container. The disk then becomes visible within the "Media Browser" and the /media directory of each addon.

NOTE<sup>1</sup>: It works only and only on HassOS on other hosts it is not tested and most likely it does not work.

NOTE<sup>2</sup>: It is necessary to enable the access to the SSH port 22222 of the host.   Read the HassOS [Developers Documentation](https://developers.home-assistant.io/docs/operating-system/debugging/#home-assistant-operating-system) or use the [Configutarion Addon](https://community.home-assistant.io/t/add-on-hassos-ssh-port-22222-configurator/264109).

NOTE<sup>3</sup>: It is necessary to pass the SSH private key for root access to the host. Be sure to use secrets files to protect the key from people who don't have access to it. 

NOTE<sup>4</sup>: If the disk in the "Media Browser" is seen empty try restarting Homeassitant.
 
**WARNING: The feature is considered experimental and may cause problems or data loss.**

#### Option: `enable` (optional)

Enable/Disable host mounting option.

Defaults to `false`.

#### Option: `ssh_private_key` (optional)

The ***PRIVATE*** key for SSH access to the host on port 22222.

### Option: `veto_files` (optional)

List of files that are neither visible nor accessible. Useful to stop clients
from littering the share with temporary hidden files
(e.g., macOS `.DS_Store` or Windows `Thumbs.db` files)

### Option: `compatibility_mode` (optional)

Setting this option to `true` will enable old legacy Samba protocols
on the Samba add-on. This might solve issues with some clients that cannot
handle the newer protocols, however, it lowers security. Only use this
when you absolutely need it and understand the possible consequences.

Defaults to `false`.

### Option: `mqtt_enable` (optional)

Setting this option to `true` will enable the use of mqtt to send disks status data.

Defaults to `true`.

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

### Common problems

* ***The disk does not mount*** : check that the Label of the partition of the disk you want to mount is case-sensitive with the label indicated in the `moredisk` parameter.

* ***In the menu `Media Browser` the folder with the name of the disk is empty*** : it happens when the homeassistant server starts before the add-on. Restart HomeAssitant from menu `Configuration->Server Controls->Server management -> RESTART`
<!--
Got questions?

You have several options to get them answered:

- The [Home Assistant Discord Chat Server][discord].
- The Home Assistant [Community Forum][forum].
- Join the [Reddit subreddit][reddit] in [/r/homeassistant][reddit]
-->

In case you've found a bug, please [open an issue on our GitHub][issue].

[issue]: https://github.com/dianlight/hassio-addons/issues
[reddit]: https://reddit.com/r/homeassistant
[repository]: https://github.com/dianlight/hassio-addons
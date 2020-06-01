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

## Configuration

Add-on configuration:

```yaml
workgroup: WORKGROUP
username: Hassio
password: 'null'
interface: ''
allow_hosts:
  - 10.0.0.0/8
  - 172.16.0.0/12
  - 192.168.0.0/16
moredisks:
  - DISKLABEL1
  - DISKLABEL2
veto_files:
  - "._*"
  - ".DS_Store"
  - Thumbs.db
compatibility_mode: false  
```

### Option: `workgroup` (required)

Change WORKGROUP to reflect your network needs.

### Option: `username` (required)

The username you would like to use to authenticate with the Samba server.

### Option: `password` (required)

The password that goes with the username configured for authentication.

### Option: `interface` (required)

The network interface Samba should listen on for incoming connections.
This option should only be used in advanced cases. In general, setting this
option is not needed.

### Option: `allow_hosts` (required)

List of hosts/networks allowed to access the shared folders.

### Option: `moredisks` (optional)

***Protection Mode must be disabled to allow this function***
List of disks or partitions label to search and share. 
The following Fs are supported:
- [X] ext3/4
- [X] fat --> ***NOTE: ACL are not supported so no TimeMachine compatibility***

Future Fs support:
- Fuse based fs
  - [ ] exFat
  - [ ] fat32
  - [ ] ntfs

### Option: `veto_files` (optional)

List of files that are neither visible nor accessible. Useful to stop clients
from littering the share with temporary hidden files
(e.g., macOS `.DS_Store` or Windows `Thumbs.db` files)

### Option: `compatibility_mode`

Setting this option to `true` will enable old legacy Samba protocols
on the Samba add-on. This might solve issues with some clients that cannot
handle the newer protocols, however, it lowers security. Only use this
when you absolutely need it and understand the possible consequences.

Defaults to `false`.

## Support
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
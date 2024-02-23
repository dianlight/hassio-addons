# Home Assistant Add-on: BeSIM

## ![#f03c15](https://via.placeholder.com/15/f03c15/f03c15.png) Important Note ![#f03c15](https://via.placeholder.com/15/f03c15/f03c15.png)

This addon has been designed, built and tested to work with HAOS (Homeassistant Operating System). The use in other types of installations is not recommended or supported

## Installation

Follow these steps to get the add-on installed on your system:

1. Navigate in your Home Assistant frontend to **Supervisor** -> **Add-on Store**.
2. Find the "BeSIM" add-on and click it.
3. Click on the "INSTALL" button.

## How to use

1. In the configuration section, control all options.
2. Save the configuration.
3. Start the add-on.
4. Check the add-on log output to see the result.

## Connection

__TODO__

## Configuration

This is an example of a configuration. **_DO NOT USE_** without making the necessary changes especially for the username, password, secret and moredisk part.
Fields between `<` and `>` indicate values that are omitted and need to be changed.

```yaml
updateonboot: false
work_as_proxy: true
upstream_dns: 1.1.1.1
```

### Option: `updateonboot` (optional)

Update `BeSIM-MQTT` component to lasr snapshoot on start

Defaults to `false`.

### Option: `work_as_proxy` (optional)

The addon also works as proxy so you can use BeSMART cloud based applications as IOS Mobile Apps.

Defaults to `false`.

### Option: `upstream_dns` (optional)

The upsream DNS to use for proxy activities

Defaults to `1.1.1.1`.

### Option: `zone_entity` (optional)

The name of the entity to get geo position wor weather service

<!--
### Option: `mqtt_enable` (optional)

Setting this option to `true` will enable the use of mqtt to send disks status data.

Defaults to `false`.

### Option: `mqtt_nexgen_entities` (optional)

Setting this option to `true` will expose mqtt new entities. This is a refactor that allow to use less CPU.

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
-->

## Support

### Do you like the Addon?
<a href="https://www.buymeacoffee.com/ypKZ2I0"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=ypKZ2I0&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" /></a>

### Common problems

In case you've found a bug, please [open an issue on our GitHub][issue].

[issue]: https://github.com/dianlight/hassio-addons/issues
[reddit]: https://reddit.com/r/homeassistant
[repository]: https://github.com/dianlight/hassio-addons

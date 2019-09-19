# Hass.io Add-ons: RPi MySensors Gateway

[![GitHub Release][releases-shield]][releases]
![Project Stage][project-stage-shield]
[![License][license-shield]](LICENSE.md)

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armhf Architecture][armhf-shield]
![Supports armv7 Architecture][armv7-shield]
![Supports i386 Architecture][i386-shield]

<!---
[![GitLab CI][gitlabci-shield]][gitlabci]
 --->
![Project Maintenance][maintenance-shield]
[![GitHub Activity][commits-shield]][commits]

<!---
[![Discord][discord-shield]][discord]
 --->

[![Buy me a coffee][buymeacoffee-shield]][buymeacoffee]

## About

A Rasperry Pi has an spi interface. So why don't connect directly an rf24 device?

Info on [MySensors pages][mysensors]

<!---
[Bookstack].

![Bookstack screenshot](images/screenshot.png)
 --->
## Note

***!ONLY!*** *nRF24L01P Chips is supported!*

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add our Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install the "RPi MySensor Gateway" add-on.
1. Start the "RPi MySensor Gateway" add-on
1. Check the logs of the "RPi MySensor Gateway" add-on to see if everything went well.

<!---
1. Default login information is admin@admin.com/password.

**NOTE**: Do not add this repository to Hass.io, please use:
`https://github.com/hassio-addons/repository`.
 --->

## Configuration

**Note**: _Remember to restart the add-on when the configuration is changed._

Example add-on configuration:

```json
{
    "rebuild": false,  
    "log_level": "debug",  
    "channel":75,
    "pa_level":"RF24_PA_MAX",
    "ce_pin":22,
    "cs_pin":24,
    "use_irq":{
        "rx_buffer":20,
        "pin":15
    },
    "use_led":{
        "err_pin": 12,
        "rx_pin": 16,
        "tx_pin": 18
    }
}
```

**Note**: _This is just an example, don't copy and paste it! Create your own!_

**Info**: _For detailed specifications go on [MySensors pages][mysensors]_

### Option: `rebuild`

Force the MySensor build to clean all **ONLY FOR TEST**
Set it `true` to enable it, `false` otherwise.

### Option: `log_level`

The `log_level` option controls the level of log output by the addon and can
be changed to be more or less verbose, which might be useful when you are
dealing with an unknown issue. Possible values are:

debug,info,notice,warn,err

- `debug`: Shows detailed debug information.
- `info`: Normal (usually) interesting events.
- `notice`: Normal (low verbose) interesting events.
- `warn`: Exceptional occurrences that are not errors.
- `err`:  Runtime errors that do not require immediate action.

Please note that each level automatically includes log messages from a
more severe level, e.g., `debug` also shows `info` messages. By default,
the `log_level` is set to `info`, which is the recommended setting unless
you are troubleshooting.


### Option: `channel`

<0-125>   RF channel for the sensor net. [76]

### Option: `pa_level`

[RF24_PA_MAX|RF24_PA_LOW] RF24 PA level. [RF24_PA_MAX]

### Option: `ce_pin`

Pin number to use for rf24 Chip-Enable.

### Option: `cs_pin`

Pin number to use for rf24 Chip-Select.

### Option: `use_irq`

Only applies if external irg pin is connected.

#### Option: `use_irq.rx_buffer`

Buffer size for incoming messages when using rf24 interrupts. [20]

#### Option: `use_irq.pin`

Pin number connected to nRF24L01P IRQ pin.

### Option: `use_led`

Only applies if led are conneted.

#### Option: `use_led.err_pin`

Error LED pin.

#### Option: `use_led.rx_pin`

Receive LED pin.

#### Option: `use_led.tx_pin`

Transmit LED pin.

## Known issues and limitations

- MQTT is not supported.
- Serial communication is not supported.
- RFM69 is not supported.
- RS485 is not supported.
- Security is not supported.

## Changelog & Releases

This repository keeps a change log using [GitHub's releases][releases]
functionality. The format of the log is based on
[Keep a Changelog][keepchangelog].

Releases are based on [Semantic Versioning][semver], and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Support

Got questions?
<!--
You have several options to get them answered:

- The [Community Hass.io Add-ons Discord chat server][discord] for add-on
  support and feature requests.
- The [Home Assistant Discord chat server][discord-ha] for general Home
  Assistant discussions and questions.
- The Home Assistant [Community Forum][forum].
- Join the [Reddit subreddit][reddit] in [/r/homeassistant][reddit]
-->

You could also [open an issue here][issue] GitHub.

## Contributing

This is an active open-source project. We are always open to people who want to
use the code or contribute to it.

We have set up a separate document containing our
[contribution guidelines](CONTRIBUTING.md).

Thank you for being involved! :heart_eyes:

## Authors & contributors

The original setup of this repository is by [Lucio Tarantino][dianlight].

<!--
For a full list of all authors and contributors,
check [the contributor's page][contributors].
-->
<!--
## We have got some Hass.io add-ons for you

Want some more functionality to your Hass.io Home Assistant instance?

We have created multiple add-ons for Hass.io. For a full list, check out
our [GitHub Repository][repository].
-->
## License

MIT License

Copyright (c) 2019 Lucio Tarantino

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

[mysensors]: https://www.mysensors.org/build/raspberry#configure
[aarch64-shield]: https://img.shields.io/badge/aarch64-no-green.svg
[alpine-packages]: https://pkgs.alpinelinux.org/packages
[amd64-shield]: https://img.shields.io/badge/amd64-no-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[bookstack]: https://www.bookstackapp.com/
[buymeacoffee-shield]: https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-2.svg
[buymeacoffee]: https://www.buymeacoffee.com/sinclairpaul
[commits-shield]: https://img.shields.io/github/commit-activity/y/hassio-addons/addon-bookstack.svg
[commits]: https://github.com/hassio-addons/addon-bookstack/commits/master
[contributors]: https://github.com/hassio-addons/addon-bookstack/graphs/contributors
[discord-ha]: https://discord.gg/c5DvZ4e
[discord-shield]: https://img.shields.io/discord/478094546522079232.svg
[discord]: https://discord.me/hassioaddons
[forum-shield]: https://img.shields.io/badge/community-forum-brightgreen.svg
[forum]: https://community.home-assistant.io/t/community-hass-io-xxxxx/xxxxx
[dianlight]: https://github.com/dianlight
[gitlabci-shield]: https://gitlab.com/hassio-addons/addon-bookstack/badges/master/pipeline.svg
[gitlabci]: https://gitlab.com/hassio-addons/addon-bookstack/pipelines
[home-assistant]: https://home-assistant.io
[i386-shield]: https://img.shields.io/badge/i386-no-green.svg
[issue]: https://github.com/hassio-addons/addon-bookstack/issues
[keepchangelog]: http://keepachangelog.com/en/1.0.0/
[license-shield]: https://img.shields.io/github/license/hassio-addons/addon-bookstack.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2019.svg
[npm-packages]: https://www.npmjs.com
[project-stage-shield]: https://img.shields.io/badge/project%20stage-experimental-yellow.svg
[reddit]: https://reddit.com/r/homeassistant
[releases-shield]: https://img.shields.io/github/release/hassio-addons/addon-bookstack.svg
[releases]: https://github.com/hassio-addons/addon-bookstack/releases
[repository]: https://github.com/hassio-addons/repository
[semver]: http://semver.org/spec/v2.0.0.htm
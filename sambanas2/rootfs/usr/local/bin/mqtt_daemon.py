# python 3.11

import logging
import subprocess
import time
import argparse
import collections
import asyncio
import json
import os
import typing
import hashlib
from pySMART import DeviceList, Device
from pySMART.interface import NvmeAttributes, AtaAttributes
import psutil
from psutil._common import sdiskio, sdiskusage
from ha_mqtt_discoverable import Settings, DeviceInfo
from ha_mqtt_discoverable.sensors import Sensor, SensorInfo, BinarySensor
from ha_mqtt_discoverable.sensors import BinarySensorInfo
import signal
from typing import Any, Callable, List, Literal, NoReturn, Self, Tuple, Union
import re
import humanize
from abc import ABC, abstractmethod
from diskinfo import Disk

# config = configparser.ConfigParser( strict=False )
# config.read("/etc/samba/smb.conf")

# Get the arguments from the command-line except the filename
ap = argparse.ArgumentParser()

# Add the arguments to the parser
ap.add_argument("-b", "--broker", required=True, help="Broker")
ap.add_argument("-p", "--port", required=True, help="Broker Port")
ap.add_argument("-u", "--user", required=True, help="Broker User")
ap.add_argument("-P", "--password", required=True, help="Broker Password")
ap.add_argument("-t", "--topic", required=False, help="Topic", default="sambanas")
ap.add_argument(
    "-i",
    "--hdidle_log",
    required=False,
    help="HD_IDLE log to listen for sleeping drivers",
)
ap.add_argument(
    "-T", "--discovery_topic", required=False, help="Topic", default="homeassistant"
)
ap.add_argument(
    "-d", "--persist_discovery", required=False, help="Topic", default=True, type=bool
)
ap.add_argument(
    "-v", "--addon_version", required=False, help="Addon Version", default="latest"
)
ap.add_argument(
    "-l",
    "--logLevel",
    required=False,
    default="WARNING",
    choices=[
        "ALL",
        "TRACE",
        "DEBUG",
        "INFO",
        "NOTICE",
        "WARNING",
        "ERROR",
        "CRITICAL",
        "FATAL",
        "OFF",
    ],
)


args: dict[str, Any] = vars(ap.parse_args())


match str(args["logLevel"]).upper():
    case "DEBUG" | "ALL" | "TRACE":
        logging.basicConfig(level=logging.DEBUG)
    case "NOTICE":
        logging.basicConfig(level=logging.INFO)
    case "WARNING" | "INFO":
        logging.basicConfig(level=logging.WARNING)
    case "ERROR":
        logging.basicConfig(level=logging.ERROR)
    case "CRITICAL" | "FATAL":
        logging.basicConfig(level=logging.CRITICAL)
    case "OFF":
        logging.basicConfig(level=logging.NOTSET)
    case "_":
        logging.basicConfig(level=logging.WARNING)

mqtt_settings = Settings.MQTT(
    host=args["broker"],
    port=int(args["port"]),
    username=args["user"],
    password=args["password"],
    discovery_prefix=args["discovery_topic"],
    state_prefix=args["topic"],
)


# Global Sensors regitry
class ConfigEntity(ABC):
    def __init__(
        self,
        sensorInfo: Union[SensorInfo, BinarySensorInfo],
        state_function: Callable[[Self], Any],
        attributes_function: Callable[[Self], dict[str, Any]] | None = None,
    ) -> None:
        self.sensorInfo: SensorInfo | BinarySensorInfo = sensorInfo
        self.state_function = state_function
        self.attributes_function = attributes_function
        self.sensor: Union[Sensor, BinarySensor] = None  # type: ignore

    def createSensor(self) -> Self:
        if self.sensor is not None:
            return self.sensor  # type: ignore
        settings = Settings(mqtt=mqtt_settings, entity=self.sensorInfo)
        if isinstance(self.sensorInfo, BinarySensorInfo):
            self.sensor = BinarySensor(settings)  # type: ignore
            logging.debug(
                "BinarySensor '%s' created", self.sensor.generate_config()["name"]
            )
        elif isinstance(self.sensorInfo, SensorInfo):
            self.sensor = Sensor(settings)  # type: ignore
            logging.debug("Sensor '%s' created", self.sensor.generate_config()["name"])
        return self

    @abstractmethod
    def detstroy(self) -> None:
        pass


class ConfigEntityAutonomous(ConfigEntity):
    def detstroy(self) -> None:
        self.sensor.delete()


class ConfigEntityFromDevice(ConfigEntity):
    def __init__(
        self,
        sensorInfo: Union[SensorInfo, BinarySensorInfo],
        device: Device,
        state_function: Callable[[Self], Any],
        attributes_function: Callable[[Self], dict[str, Any]] = None,  # type: ignore
    ):
        super().__init__(sensorInfo, state_function, attributes_function)
        self.device = device

    def detstroy(self) -> None:
        self.sensor.delete()


class ConfigEntityFromHDIdle(ConfigEntity):
    def __init__(
        self,
        sensorInfo: Union[SensorInfo, BinarySensorInfo],
        device: Device,
        state_function: Callable[[Self], Any],
        attributes_function: Callable[[Self], dict[str, Any]] = None,  # type: ignore
    ):
        super().__init__(sensorInfo, state_function, attributes_function)
        self.device = device

    def detstroy(self) -> None:
        self.sensor.delete()


class ConfigEntityFromIoStat(ConfigEntity):
    def __init__(
        self,
        sensorInfo: Union[SensorInfo, BinarySensorInfo],
        iostat_device: str,
        state_function: Callable[[Self], Any],
        attributes_function: Callable[[Self], dict[str, Any]] | None = None,
    ) -> None:
        super().__init__(sensorInfo, state_function, attributes_function)
        self.iostat_device: str = iostat_device
        self._iostat: collections.deque[tuple[int, dict[str, sdiskio] | None]] = (
            collections.deque([(0, None), (0, None)], maxlen=2)
        )

    @property
    def iostat(self) -> tuple[int, dict[str, sdiskio] | None]:
        return self._iostat[1]

    @property
    def h_iostat(self) -> tuple[int, dict[str, sdiskio] | None]:
        return self._iostat[0]

    def addIostat(self, iostat: dict) -> None:
        self._iostat.append((time.time_ns(), iostat.copy()))

    def detstroy(self) -> None:
        self.sensor.delete()


class ConfigEntityFromSamba(ConfigEntity):
    def __init__(
        self,
        sensorInfo: Union[SensorInfo, BinarySensorInfo],
        samba: dict,
        state_function: Callable[[Self], Any],
        attributes_function: Callable[[Self], dict[str, Any]] | None = None,
    ) -> None:
        super().__init__(sensorInfo, state_function, attributes_function)
        self.samba = samba

    def detstroy(self):
        self.sensor.delete()


def sambaMetricCollector() -> dict[str, Any]:
    # smbstatus gets report of current samba server connections
    try:
        p = subprocess.Popen(["smbstatus", "-jf"], stdout=subprocess.PIPE)
        output, err = p.communicate()
        jsondata = json.loads(output.decode())

        logging.debug("SmbClient: %s", jsondata)
    except Exception:
        logging.warning("Exception on smbstat comunication!")
        jsondata = {}

    data = {"samba_version": jsondata.get("version", "Unknown")}
    if "sessions" in jsondata:
        data["users"] = len(jsondata["sessions"])
        data["users_json"] = jsondata["sessions"]
    else:
        data["users"] = 0
        data["users_json"] = {}

    data["connections"] = len(jsondata["tcons"]) if "tcons" in jsondata else 0
    if "open_files" in jsondata:
        data["open_files"] = len(jsondata["open_files"])
    else:
        data["open_files"] = 0

    logging.debug(data)
    return data


sensorList: List[Tuple[str, ConfigEntity]] = []
devicePowerStatus: dict[str, str] = {}

# Main device SambaNas
samba: dict[str, Any] = sambaMetricCollector()
sambanas_device_info = DeviceInfo(
    name="SambaNas",
    model="Addon",
    manufacturer="@Dianlight",
    sw_version=samba["samba_version"],
    hw_version=args["addon_version"],
    identifiers=[os.getenv("HOSTNAME", default="local_test")],
)

devlist = DeviceList()
psdata: dict[str, sdiskio] = psutil.disk_io_counters(perdisk=True, nowrap=True)

for dev_name in psdata.keys():
    if re.search(r"\d+$", dev_name):
        continue
    dev = Device(dev_name)
    disk_device_info = DeviceInfo(
        name=f"SambaNas Disk {dev_name}",
        model=dev.model,
        sw_version=dev.firmware,
        # connections=[[dev_name,sambanas_device_info.identifiers[0]]],
        identifiers=[dev.serial or "Unknown(%s)" % dev_name],
        via_device=sambanas_device_info.identifiers[0],  # type: ignore
    )

    # sambanas_device_info.connections.append([dev_name,disk_device_info.identifiers[0]])

    def smartAssesmentAttribute(ce: ConfigEntityFromDevice) -> dict[str, Any]:
        attributes: dict[str, Any] = {
            "smart_capable": ce.device.smart_capable,
            "smart_enabled": ce.device.smart_enabled,
            "assessment": ce.device.assessment,
            "messages": ce.device.messages,
            "rotation_rate": ce.device.rotation_rate,
            "_test_running": ce.device._test_running,
            "_test_progress": ce.device._test_progress,
        }
        if ce.device.if_attributes is None:
            return attributes
        if isinstance(ce.device.if_attributes, AtaAttributes):
            atattrs: AtaAttributes = ce.device.if_attributes
            for atattr in atattrs.legacyAttributes:
                if atattr is None:
                    continue
                attributes[atattr.name] = atattr.raw
                health_value: Literal["OK", "FAIL"] = (
                    "OK"
                    if (atattr.thresh is not None and atattr.worst > atattr.thresh)
                    else "FAIL"
                )
                attributes[f"{atattr.name}_Health"] = health_value
        elif isinstance(ce.device.if_attributes, NvmeAttributes):
            nwmattrs: NvmeAttributes = ce.device.if_attributes
            for nwmattr in nwmattrs.__dict__.keys():
                if nwmattrs.__dict__[nwmattr] is None:
                    continue
                attributes[nwmattr] = nwmattrs.__dict__[nwmattr]
        return attributes

    if dev.smart_capable:
        smartAssessment = ConfigEntityFromDevice(
            sensorInfo=BinarySensorInfo(
                name=f"S.M.A.R.T {dev.name}",
                unique_id=hashlib.md5(
                    f"S.M.A.R.T {dev.name}".encode("utf-8")
                ).hexdigest(),
                device=disk_device_info,
                # enabled_by_default= dev.smart_capable
                device_class="problem",
            ),
            state_function=lambda ce: ce.device.assessment != "PASS",
            attributes_function=smartAssesmentAttribute,
            device=dev,
        )
        sensorList.append((f"smart_{dev.name}", smartAssessment.createSensor()))

    if args["hdidle_log"] is not None:
        hdIdleAssessment = ConfigEntityFromHDIdle(
            sensorInfo=BinarySensorInfo(
                name=f"POWER {dev.name}",
                unique_id=hashlib.md5(f"POWER {dev.name}".encode("utf-8")).hexdigest(),
                device=disk_device_info,
                device_class="power",
            ),
            state_function=lambda ce: devicePowerStatus.get(ce.device.name) != "spindown",
            attributes_function=lambda ce: {"pipe_file": args["hdidle_log"] + "s"},
            device=dev,
        )
        sensorList.append((f"power_{dev.name}", hdIdleAssessment.createSensor()))

    def totalDiskRate(ce: ConfigEntityFromIoStat) -> float | Literal[0]:

        if (
            ce.h_iostat[0] in [0, ce.iostat[0]] or ce.iostat[1] is None or ce.h_iostat[1] is None
        ):
            return 0
        t_read: int = int(ce.iostat[1][ce.iostat_device].read_bytes) - int(
            ce.h_iostat[1][ce.iostat_device].read_bytes
        )
        t_write: int = int(ce.iostat[1][ce.iostat_device].write_bytes) - int(
            ce.h_iostat[1][ce.iostat_device].write_bytes
        )
        t_ns_time: int = ce.iostat[0] - ce.h_iostat[0]
        logging.debug("%s %d %d %d", ce.iostat_device, t_read, t_write, t_ns_time)
        return round(((t_read + t_write) * 1000000000 / t_ns_time) / 1024, 2)  # kB/s

    def iostatAttribute(ce: ConfigEntityFromIoStat) -> dict[str, str]:
        if ce.iostat[1] is None:
            return {}
        attributes: dict[str, str] = {
            key: getattr(ce.iostat[1][ce.iostat_device], key)
            for key in ce.iostat[1][ce.iostat_device]._fields
        }
        return attributes

    diskInfo = ConfigEntityFromIoStat(
        sensorInfo=SensorInfo(
            name=f"IOSTAT {dev.name}",
            unique_id=hashlib.md5(f"IOSTAT {dev.name}".encode("utf-8")).hexdigest(),
            device=disk_device_info,
            unit_of_measurement="kB/s",
            device_class="data_rate",
        ),
        state_function=totalDiskRate,
        attributes_function=iostatAttribute,
        iostat_device=dev.name,
    )

    sensorList.append((f"iostat_{dev.name}", diskInfo.createSensor()))

    partitionDevices: typing.Dict[str, DeviceInfo] = {}

    for partition in Disk(dev_name).get_partition_list():
        if (partition.get_fs_label() or partition.get_fs_uuid()) == "":
            continue
        if not partition.get_name() in partitionDevices:
            partitionDevices[partition.get_name()] = DeviceInfo(
                name=f"SambaNas Partition {partition.get_fs_label() or partition.get_fs_uuid()}",
                model=partition.get_fs_label() or partition.get_fs_uuid(),
                manufacturer=partition.get_fs_type(),
                identifiers=[partition.get_fs_label() or partition.get_fs_uuid()],
                via_device=disk_device_info.identifiers[0],  # type: ignore
            )
        try:
            sdiskparts = list(
                filter(
                    lambda part: part.device.endswith(partition.get_name()),
                    psutil.disk_partitions(),
                )
            )
            if sdiskparts and sdiskparts[0] and sdiskparts[0].mountpoint:
                if partitionDevices[partition.get_name()].identifiers is None:
                    partitionDevices[partition.get_name()].identifiers = []
                if isinstance(partitionDevices[partition.get_name()].identifiers, str):
                    partitionDevices[partition.get_name()].identifiers = [
                        str(partitionDevices[partition.get_name()].identifiers)
                    ]
                partitionDevices[partition.get_name()].identifiers.append(  # type: ignore
                    sdiskparts[0].mountpoint
                )
        finally:
            pass

    logging.debug(
        "Generated %d Partitiond Device for %s", len(partitionDevices), dev.name
    )

    for partition_device, partitionDeviceInfo in partitionDevices.items():
        partitionInfo = ConfigEntityFromIoStat(
            sensorInfo=SensorInfo(
                name=f"IOSTAT {partitionDeviceInfo.model}",
                unique_id=hashlib.md5(
                    f"IOSTAT {partitionDeviceInfo.model}".encode("utf-8")
                ).hexdigest(),
                device=partitionDeviceInfo,
                unit_of_measurement="kB/s",
                device_class="data_rate",
            ),
            state_function=totalDiskRate,
            attributes_function=iostatAttribute,
            iostat_device=partition_device,
        )

        sensorList.append((f"iostat_{partition_device}", partitionInfo.createSensor()))

        def usageAttribute(ce: ConfigEntityAutonomous) -> dict[str, str]:
            if ce.sensorInfo.device is None or ce.sensorInfo.device.identifiers is None:
                return {}
            usage: sdiskusage = psutil.disk_usage(ce.sensorInfo.device.identifiers[-1])
            attributes: dict[str, str] = {
                "used": humanize.naturalsize(usage.used),
                "total": humanize.naturalsize(usage.total),
                "free": humanize.naturalsize(usage.free),
            }
            return attributes

        def partitionUsage(ce: ConfigEntityAutonomous) -> Any:
            if ce.sensorInfo.device is None or ce.sensorInfo.device.identifiers is None:
                return
            logging.debug(
                "Collecting Usage from %s [%s]",
                ce.sensorInfo.device.identifiers,
                ce.sensorInfo.device.identifiers[-1],
            )
            return psutil.disk_usage(ce.sensorInfo.device.identifiers[-1]).percent

        if (
            partitionDeviceInfo.identifiers is not None and len(partitionDeviceInfo.identifiers) > 1
        ):
            partitionInfo = ConfigEntityAutonomous(
                sensorInfo=SensorInfo(
                    name=f"Usage {partitionDeviceInfo.model}",
                    unique_id=hashlib.md5(
                        f"Usage {partitionDeviceInfo.model}".encode("utf-8")
                    ).hexdigest(),
                    device=partitionDeviceInfo,
                    icon="mdi:harddisk",
                    unit_of_measurement="%",
                    device_class="power_factor",
                ),
                state_function=partitionUsage,
                attributes_function=usageAttribute,
            )

            sensorList.append(
                (f"usage_{partition_device}", partitionInfo.createSensor())
            )

sambaUsers = ConfigEntityFromSamba(
    sensorInfo=SensorInfo(
        name="Online Users",
        device=sambanas_device_info,
        unique_id=hashlib.md5("Online Users".encode("utf-8")).hexdigest(),
    ),
    state_function=lambda ce: ce.samba["users"],
    samba=samba,
)
sensorList.append(("samba_users", sambaUsers.createSensor()))
sambaConnections = ConfigEntityFromSamba(
    sensorInfo=SensorInfo(
        name="Active Connections",
        device=sambanas_device_info,
        unique_id=hashlib.md5("Active Connections".encode("utf-8")).hexdigest(),
    ),
    state_function=lambda ce: ce.samba["connections"],
    attributes_function=lambda ce: {"open_files": ce.samba["open_files"]},
    samba=samba,
)
sensorList.append(("samba_connections", sambaConnections.createSensor()))

tasks: list[asyncio.Task] = []


async def publish_states() -> NoReturn:
    while True:
        for sensor in sensorList:
            if isinstance(sensor[1], ConfigEntityAutonomous):
                logging.info("Updating sensor %s", sensor[0])
                sensor[1].sensor.set_state(sensor[1].state_function(sensor[1]))  # type: ignore
                if sensor[1].attributes_function is not None:
                    sensor[1].sensor.set_attributes(
                        sensor[1].attributes_function(sensor[1])
                    )
        await asyncio.sleep(5)


async def publish_idle_states() -> NoReturn:
    with open(args["hdidle_log"]) as pipe_hdidle:
        while True:
            line = pipe_hdidle.readline()
            if len(line) == 0:
                logging.error(f"Pipe Broken {args["hdidle_log"]}!")
                break
            # Parse line with ilde status
            # Aug  8 00:14:55 enterprise hd-idle[9958]: sda spindown
            # Aug  8 00:14:55 enterprise hd-idle[9958]: sdb spindown
            # Aug  8 00:14:56 enterprise hd-idle[9958]: sdc spindown
            # Aug  8 00:17:55 enterprise hd-idle[9958]: sdb spinup
            # Aug  8 00:28:55 enterprise hd-idle[9958]: sdb spindown
            disk, status = line.split(' ', maxsplit=1)
            logging.info("Disk %s change to status %s", disk, status.strip())
            devicePowerStatus[disk] = status.strip()
            logging.debug(devicePowerStatus)
            for sensor in sensorList:
                if isinstance(sensor[1], ConfigEntityFromHDIdle) and sensor[1].device.name == disk:
                    logging.info("Updating sensor %s", sensor[0])
                    if isinstance(sensor[1].sensor, BinarySensor):
                        sensor[1].sensor.update_state(sensor[1].state_function(sensor[1]))
                    elif isinstance(sensor[1].sensor, Sensor):
                        sensor[1].sensor.set_state(sensor[1].state_function(sensor[1]))  # type: ignore
                    if sensor[1].attributes_function is not None:
                        sensor[1].sensor.set_attributes(
                            sensor[1].attributes_function(sensor[1])
                        )


async def publish_device_states() -> NoReturn:
    while True:
        for sensor in sensorList:
            if isinstance(sensor[1], ConfigEntityFromDevice):
                logging.info(
                    "Updating Device sensor %s (pw:%s)",
                    sensor[0],
                    devicePowerStatus.get(sensor[1].device.name),
                )

                if devicePowerStatus.get(sensor[1].device.name) == "spindown":
                    continue

                sensor[1].device.update()
                if isinstance(sensor[1].sensor, BinarySensor):
                    sensor[1].sensor.update_state(sensor[1].state_function(sensor[1]))
                elif isinstance(sensor[1].sensor, Sensor):
                    sensor[1].sensor.set_state(sensor[1].state_function(sensor[1]))
                if sensor[1].attributes_function is not None:
                    sensor[1].sensor.set_attributes(
                        sensor[1].attributes_function(sensor[1])
                    )
        await asyncio.sleep(5)


async def publish_iostate_states() -> NoReturn:
    while True:

        iostate: dict[str, sdiskio] = psutil.disk_io_counters(perdisk=True, nowrap=True)

        for sensor in sensorList:
            if isinstance(sensor[1], ConfigEntityFromIoStat):
                logging.info("Updating Iostat sensor %s", sensor[0])
                sensor[1].addIostat(iostate)
                sensor[1].sensor.set_state(sensor[1].state_function(sensor[1]))  # type: ignore
                if sensor[1].attributes_function is not None:
                    sensor[1].sensor.set_attributes(
                        sensor[1].attributes_function(sensor[1])
                    )
        await asyncio.sleep(1)


async def publish_samba_states() -> NoReturn:
    while True:
        samba: dict[str, Any] = sambaMetricCollector()

        for sensor in sensorList:
            if isinstance(sensor[1], ConfigEntityFromSamba):
                logging.info("Updating Samba sensor %s", sensor[0])
                sensor[1].samba = samba
                sensor[1].sensor.set_state(sensor[1].state_function(sensor[1]))  # type: ignore
                if sensor[1].attributes_function is not None:
                    sensor[1].sensor.set_attributes(
                        sensor[1].attributes_function(sensor[1])
                    )
        await asyncio.sleep(10)


async def run() -> None:

    def doneCallback(task):
        for sensor in sensorList:
            logging.info("Unpublish sensor %s", sensor[0])
            sensor[1].sensor.delete()

    # Loop Status publish
    async with asyncio.TaskGroup() as tg:
        if args["hdidle_log"] is not None:
            task = tg.create_task(publish_idle_states(), name="Read and Publish HD-IDLE states")
            task.add_done_callback(doneCallback)
            tasks.append(task)
        task = tg.create_task(publish_states(), name="Publish States")
        task.add_done_callback(doneCallback)
        tasks.append(task)
        task = tg.create_task(publish_device_states(), name="Publish Device States")
        task.add_done_callback(doneCallback)
        tasks.append(task)
        task = tg.create_task(publish_iostate_states(), name="Publish IO States")
        task.add_done_callback(doneCallback)
        tasks.append(task)
        task = tg.create_task(publish_samba_states(), name="Publish Samba States")
        task.add_done_callback(doneCallback)
        tasks.append(task)

    loop = asyncio.get_event_loop()

    async def ask_exit(signame):
        logging.warning("Signal %x. Unpublish %d sensors", signame, len(sensorList))

        loop.remove_signal_handler(signame)

        for task in tasks:
            try:
                task.cancel()
            finally:
                logging.warning(f"Task {task.get_name()} cancelled!")

    for signame in ('SIGINT', 'SIGTERM', 'SIGHUP'):
        loop.add_signal_handler(getattr(signal, signame),
                                lambda signame=signame: asyncio.create_task(ask_exit(signame)))

    await asyncio.gather(*tasks)


if __name__ == "__main__":
    asyncio.run(run())

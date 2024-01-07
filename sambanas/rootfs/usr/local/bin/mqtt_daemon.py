# python 3.11

import logging
from copy import deepcopy
import subprocess
import time
import argparse
import configparser
import collections
import json
import os
import uuid
from pySMART import Attribute, DeviceList, Device
from pySMART.interface import NvmeAttributes, AtaAttributes
import psutil
from psutil._common import sdiskio
from ha_mqtt_discoverable import Settings, DeviceInfo
from ha_mqtt_discoverable.sensors import Sensor, SensorInfo, BinarySensor, BinarySensorInfo
import signal
from typing import Any, Callable,List, Self, Tuple, Union
import re
import humanize

#from paho.mqtt import client as mqtt_client

config = configparser.ConfigParser( strict=False )
config.read("/etc/samba/smb.conf")

# Get the arguments from the command-line except the filename
ap = argparse.ArgumentParser()

# Add the arguments to the parser
ap.add_argument("-b", "--broker", required=True,
   help="Broker")
ap.add_argument("-p", "--port", required=True,
   help="Broker Port")
ap.add_argument("-u", "--user", required=True,
   help="Broker User")
ap.add_argument("-P", "--password", required=True,
   help="Broker Password")
ap.add_argument("-t", "--topic", required=False,
   help="Topic", default="sambanas")
ap.add_argument("-d", "--persist_discovery", required=False,
   help="Topic", default=True, type=bool)
ap.add_argument("-v", "--addon_version", required=False,
   help="Addon Version", default="latest")
ap.add_argument("-l", "--logLevel", required= False, default='WARNING',choices=['DEBUG','INFO','WARNING','ERROR','CRITICAL'])

args = vars(ap.parse_args())


match args['logLevel']:
    case 'DEBUG':
        logging.basicConfig(level=logging.DEBUG)
    case 'INFO':
        logging.basicConfig(level=logging.INFO)
    case 'WARNING':
        logging.basicConfig(level=logging.WARNING)
    case 'ERROR':
        logging.basicConfig(level=logging.ERROR)
    case 'CRITICAL':
        logging.basicConfig(level=logging.CRITICAL)
    case '_':
        logging.basicConfig(level=logging.WARNING)



mqtt_settings = Settings.MQTT(host=args['broker'],
                              port=int(args["port"]),
                              username=args['user'],
                              password=args['password'],
                              discovery_prefix="test",
                              state_prefix=args['topic'])

# Global Sensors regitry
class ConfigEntity:

    def __init__(self, sensorInfo:Union[SensorInfo,BinarySensorInfo],
                  state_function: Callable[[Self],Any], 
                  attributes_function:Callable[[Self],List[Tuple[str,Any]]] = None,
                  device:Device = None,
                  iostat_device:str = None):
        self.sensorInfo = sensorInfo
        self.state_function = state_function
        self.attributes_function = attributes_function
        self.device = device
        self.samba = {
            "users":0,
            "users_json":dict(),
            "connections":0,
            "open_files":0,
        }
        self.iostat_device = iostat_device
        self.sensor:Union[Sensor,BinarySensor] = None
        self._iostat:List[Tuple[int,dict[str,sdiskio]]] = collections.deque([(0,None),(0,None)],maxlen=2)


    @property
    def iostat(self) -> Tuple[int,dict[str,sdiskio]]:
        return self._iostat[1]

    @property
    def h_iostat(self) ->Tuple[int,dict[str,sdiskio]]:
        return self._iostat[0]
    
    def createSensor(self) -> Self:
        if self.sensor != None: return self.sensor
        settings = Settings(mqtt=mqtt_settings,entity=self.sensorInfo)
        if isinstance(self.sensorInfo,BinarySensorInfo):
            self.sensor = BinarySensor(settings)
        elif isinstance(self.sensorInfo,SensorInfo):
            self.sensor = Sensor(settings)
        logging.debug("Sensor '%s' created",self.sensor.generate_config()['name'])    
        return self   

    def addIostat(self,iostat:dict):
        self._iostat.append((time.time_ns(),iostat.copy()))

def sambaMetricCollector():
    data={}
    
##smbstatus gets report of current samba server connections
    p = subprocess.Popen(['smbstatus','-jf'], stdout=subprocess.PIPE)
    output, err = p.communicate()
    jsondata = json.loads(output.decode())

    logging.debug("SmbClient: %s",jsondata)

    data['samba_version']=jsondata['version']
    if 'sessions' in jsondata:
        data['users']=len(jsondata['sessions'])
        data['users_json']=jsondata['sessions']
    else:
        data['users']=0
        data['users_json']={}

    if 'tcons' in jsondata:
        data['connections']=len(jsondata['tcons'])
    else:
        data['connections']=0

    if 'open_files' in jsondata:
        data['open_files']=len(jsondata['open_files'])
    else:
        data['open_files']=0
    
    return data

             

sensorList:List[Tuple[str,ConfigEntity]] = []

# Main device SambaNas
samba = sambaMetricCollector()
sambanas_device_info = DeviceInfo(name="SambaNas",
                                  model="Addon",
                                  manufacturer="@Dianlight",
#                                  sw_version=os.popen('smbd -V').read().strip(),
                                  sw_version=samba['samba_version'],
                                  hw_version=args['addon_version'],
                                  identifiers=[os.getenv('HOSTNAME')])

sambaUsers = ConfigEntity(sensorInfo = SensorInfo(name="SambaNas Users",device=sambanas_device_info,unique_id=str(uuid.uuid4())),
                               state_function= lambda ce: ce.samba["users"])                               
sensorList.append(('samba_users',sambaUsers.createSensor()))
sambaConnections = ConfigEntity(sensorInfo = SensorInfo(name="SambaNas Connections",device=sambanas_device_info,unique_id=str(uuid.uuid4())),
                               state_function= lambda ce: ce.samba["connections"],
                               attributes_function= lambda ce: ('open_files',ce.samba['open_files'])
                               )                               
sensorList.append(('samba_connections',sambaConnections.createSensor()))


devlist = DeviceList()
psdata = psutil.disk_io_counters(perdisk=True,nowrap=True)

for dev_name in psdata.keys():
    if re.search(r'\d+$',dev_name): continue
    dev = Device(dev_name)
    disk_device_info = DeviceInfo(name=f"SambaNas Disk {dev_name}",
                                  model=dev.model,
                                  sw_version=dev.firmware,
                                  identifiers=[dev.serial or "Unknown(%s)" % dev_name],
                                  via_device=os.getenv('HOSTNAME'))
    
    def smartAssesmentAttribute(ce:ConfigEntity) -> List[Tuple[str,Any]]:
        attributes:List[Tuple[str,str]] = []
        attributes.append(('messages',ce.device.messages))
        attributes.append(('rotation_rate',ce.device.rotation_rate))
        attributes.append(('_test_running',ce.device._test_running))
        attributes.append(('_test_progress_',ce.device._test_progress))
        if ce.device.if_attributes == None: return attributes
        if isinstance(ce.device.if_attributes,AtaAttributes):
            atattrs:AtaAttributes = ce.device.if_attributes
            for atattr in atattrs.legacyAttributes:
                if atattr == None: continue
                attributes.append((atattr.name,atattr.raw)) 
                health_value = (atattr.worst > atattr.thresh) if "OK" else "FAIL"
                attributes.append((atattr.name+"_Health",health_value))
        elif isinstance(ce.device.if_attributes,NvmeAttributes):
            nwmattrs:NvmeAttributes = ce.device.if_attributes
            for nwmattr in nwmattrs.__dict__.keys():
                if nwmattrs[nwmattr] == None: continue
                attributes.append((nwmattr,nwmattrs[nwmattr]))
        return attributes

    
    smartAssessment = ConfigEntity(sensorInfo = SensorInfo(name=f"SambaNas S.M.A.R.T {dev.name}",
                                                           unique_id=str(uuid.uuid4()),
                                                           device=disk_device_info,
                                                           device_class='problem'),
                               state_function= lambda ce: ce.device.assessment != 'PASS',
                               attributes_function=smartAssesmentAttribute,
                               device=dev)
    sensorList.append((f'smart_{dev.name}',smartAssessment.createSensor()))    


    def totalDiskRate(ce:ConfigEntity):

        if ce.h_iostat[0] == 0 or ce.h_iostat[0] == ce.iostat[0]: return 0
        t_read = int(ce.iostat[1][ce.iostat_device].read_bytes) - int(ce.h_iostat[1][ce.iostat_device].read_bytes)
        t_write =  int(ce.iostat[1][ce.iostat_device].write_bytes) - int(ce.h_iostat[1][ce.iostat_device].write_bytes)
        t_ns_time = ce.iostat[0] - ce.h_iostat[0]
        logging.debug("%s %d %d %d",ce.iostat_device,t_read,t_write,t_ns_time)
        return round(((t_read+t_write)*1000000000/t_ns_time)/1024,2) # kB/s


    def iostatAttribute(ce:ConfigEntity) -> List[Tuple[str,str]]:
        attributes:List[Tuple[str,str]] = []
        for key in ce.iostat[1][ce.iostat_device]._fields:
            attributes.append((key,getattr(ce.iostat[1][ce.iostat_device],key)))
        return attributes
    

    diskInfo = ConfigEntity(sensorInfo= SensorInfo(name=f"Sambanas IOSTAT {dev.name}",
                                                   unique_id=str(uuid.uuid4()),
                                                   device=disk_device_info,
                                                   unit_of_measurement='kB/s',
                                                   device_class='data_rate'),
                            state_function= totalDiskRate,
                            attributes_function= iostatAttribute,
                            iostat_device=dev.name)
    
    sensorList.append((f'iostat_{dev.name}',diskInfo.createSensor()))

    partitionDevices:dict[str:DeviceInfo]={}
    for partition in psutil.disk_partitions():
        partition_device = os.path.basename(partition.device)
        if not partition_device.startswith(dev.name): continue
        if not partition_device in partitionDevices:
            partitionDevices[partition_device] = DeviceInfo(name=f"SambaNas Partition {partition_device}",
                                        model=partition.fstype,
                                        identifiers=[partition.mountpoint],
                                        via_device=dev.serial
            )
        else:
            partitionDevices[partition_device].identifiers.append(partition.mountpoint)


    logging.debug("Generated %d Partitiond Device for %s",len(partitionDevices),dev.name)

    for partition_device, partition in partitionDevices.items():
        partitionInfo = ConfigEntity(sensorInfo= SensorInfo(name=f"Sambanas IOSTAT {partition_device}",
                                                            unique_id=str(uuid.uuid4()),
                                                            device=partitionDevices[partition_device],
                                                            unit_of_measurement='kB/s',
                                                            device_class='data_rate'),
                                state_function= totalDiskRate,
                                attributes_function= iostatAttribute,
                                iostat_device=partition_device)
        
        sensorList.append((f'iostat_{partition_device}',partitionInfo.createSensor()))

        def usageAttribute(ce:ConfigEntity) -> List[Tuple[str,str]]:
            usage = psutil.disk_usage(ce.sensorInfo.device.identifiers[0])
            attributes:List[Tuple[str,str]] = [
                ('used',humanize.naturalsize(usage.used)),
                ('total',humanize.naturalsize(usage.total)),
                ('free',humanize.naturalsize(usage.free)),
            ]
            return attributes

        partitionInfo = ConfigEntity(sensorInfo= SensorInfo(name=f"Sambanas Usage {partition_device}",
                                                            unique_id=str(uuid.uuid4()),
                                                            device=partitionDevices[partition_device],
                                                            icon="mdi:harddisk",
                                                            unit_of_measurement='%',
                                                            device_class='power_factor'),
                                state_function= lambda ce: psutil.disk_usage(ce.sensorInfo.device.identifiers[0]).percent,
                                attributes_function= usageAttribute,
                                iostat_device=partition_device)
        
        sensorList.append((f'usage_{partition_device}',partitionInfo.createSensor()))

def handler(signum, frame):
    logging.warning("Signal %x. Unpublish %d sensors",signum, len(sensorList))
    for sensor in sensorList:
        logging.info("Unpublish sensor %s",sensor[0])
        sensor[1].sensor.delete()
    time.sleep(5)    
    exit(0) 
 
signal.signal(signal.SIGINT, handler=handler)
#signal.signal(signal.SIGKILL, handler=handler)
#signal.signal(signal.SIGHUP, handler=handler)




def publish_states():
    iostate = psutil.disk_io_counters(perdisk=True,nowrap=True)
    samba = sambaMetricCollector()

    for sensor in sensorList:
        logging.info("Updating sensor %s",sensor[0])
        sensor[1].addIostat(iostate)
        sensor[1].samba = samba
        if sensor[1].device != None: 
            logging.debug("->Updating Device %s",sensor[1].device)
            sensor[1].device.update()
        sensor[1].sensor.set_state(sensor[1].state_function(sensor[1]))
        if sensor[1].attributes_function != None: sensor[1].sensor.set_attributes(sensor[1].attributes_function(sensor[1]))
        

def run():    
    logging.info("")
# Loop Status publish
    while True:
        time.sleep(1)
        publish_states()



if __name__ == '__main__':
    run()

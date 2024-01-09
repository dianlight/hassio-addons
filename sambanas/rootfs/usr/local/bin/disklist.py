# python 3.11

# Return the list of mountable external Devices

from diskinfo import DiskType, DiskInfo
import subprocess
import re


di=DiskInfo()
disks=di.get_disk_list(sorting=True)
regex = r"Name:\s+(\w+)\s.*\n"
for d in disks:
    if d.get_partition_table_type()=="": continue
    plist = d.get_partition_list()
    for item in plist:
        label = item.get_fs_label()
        if label.startswith("hassos"):
            continue
        elif label != "":
            print(item.get_fs_label())
        elif item.get_fs_type() == "apfs":
            print("id:{uuid}".format(uuid=item.get_part_uuid()))
#        print(item.get_fs_label()," ",item.get_fs_type()," ",item.get_part_uuid()," ",item.get_name())

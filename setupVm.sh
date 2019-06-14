#!/bin/bash

echo "The params passed in are: $@"

if [ $EUID -ne 0 ] ; then
   echo "User:$EUID, You have to run it with sudo!"
   exit 1
fi

usage()
{
	echo -e "
	usage: $0 [options]
	options:
		-n the name of vm image
		-t the type of vm image
		-s the size of the vm disk
	"
	
}

if [ $# -lt 3 ] ;then
    usage
	exit 1
fi

imageName="myVm.img"
imageType="raw"
imageDiskSize="10G"

while getopts :s:n:t: opt
do
   case $opt in 
	s)			
		echo "Vm disk size:$OPTARG"
		imageDiskSize=$OPTARG;;
	n) 		
		echo "Vm disk image name:$OPTARG"
		imageName=$OPTARG;;
	t) 		
		echo "Vm disk image type:$OPTARG"
		imageType=$OPTARG;;
	\?)	
		echo "Unknown params: $OPTARG"
		usage
		exit 1;;
	esac
done

echo "creating the qemu image: $imageName"
qemu-img create -f $imageType $imageName $imageDiskSize

if [ $? -eq 0 ]
then
	echo "image creation success!"
fi

function setup_disk()
{
    sudo losetup -f --show "/home/lyang/myvm/$imageName" 
    
	sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk "/home/lyang/myvm/$imageName"
  o   # clear the in memory partition table
  n   # new partition
  p   # primary partition
  1   # partion number 1
      # default, start immediately after preceding partition
  +128M # 128M
  a   # make a partition bootable
  n   # new partition
  p   # primary partition
  2   # partion number 2
      # default, start immediately after preceding partition
  +4G # 4G for App1
  n   # new partition
  p   # primary partition
  3   # partion number 3
      # default, start immediately after preceding partition
  +4G # 4G for App2
  n   # new partition
  p   # primary partition
  4   # partition number 4
      # default, start immediately after preceding partition
      # default, extend partition to end of disk
  p   # print the in-memory partition table
  w   # write the partition table
EOF
    sync
	sync
    sudo partprobe -s /dev/loop0

    mkfs.ext4 /dev/loop0p1
    mkfs.ext4 /dev/loop0p2

}
sync
setup_disk


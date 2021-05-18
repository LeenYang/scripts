#!/bin/bash

echo "The params passed in are: $@"

#Must be with sudo 
if [ $EUID -ne 0 ] ; then
   echo "User:$EUID, You have to run it with root privilige, sudo!"
   exit 1
fi

diskImageName="/home/lyang/myvm/vm.img"
imageType="raw"
imageSize="10G"

kernelImageDir="/home/lyang/yocto2.5/images/changeling-hypervisor/"
kernelImage="bzImage"
rootfs_bz2="rootfs.tar.bz2"
initramfs_cpio_gz="initramfs_cpio_gz"

grub_template="/home/lyang/script/grub/grub.cfg"
initramfs="core-image-uuidboot-initramfs-changeling-hypervisor"

usage()
{
	echo -e "
	usage: $0 [options]
	options:
		-n the name of vm image
		-t the type of vm image, only raw supported for now
		-s the size of the vm disk
		-k the kernel images dir includes (bzImage, rootfs, and initramfs)
	"
	
}


function setup_disk()
{
    #sudo losetup -f --show "$imageName" 
    losetup $loopdev $diskImageName
    
	sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk "$diskImageName"
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
    sudo partprobe -s $loopdev
    for dev in $(ls ${loopdev}p*)
    do 
    	mkfs.ext4 $dev
    	blkid -s UUID $dev
    done
   
    
    #cleanup
    losetup -d $loopdev
    
}

function install_grub2()
{
	echo "Installing grub2..."
	
cat > loopdevice.map <<EOF
(hd0) /dev/loop1
EOF

	apt-get install lvm2
	apt-get install grub-pc
	losetup $loopdev $diskImageName
	
	for dev in $(ls ${loopdev}p*)
	do 
		partition=${dev##*/}
		
		if [ ! -d "/mnt_loop/$partition" ]; then			
			mkdir /mnt_loop/$partition
		fi
		mount $dev /mnt_loop/$partition
		if [ ${partition##*p} == "1" ]; then
			echo "$partition install grub" 
			grub-install --no-floppy --grub-mkdevicemap=loopdevice.map --modules="part_msdos" --boot-directory=/mnt_loop/$partition/boot $loopdev
			
			#copy the grub.cfg template
			rsync /home/lyang/script/grub/grub.cfg.template /mnt_loop/$partition/boot/grub/
			sync
		fi
		umount $dev
	done
	sync
    losetup -d $loopdev
}

function install_kernel()
{
	echo "Installing bzImage, rootfs, initramfs...."
	
	losetup $loopdev $diskImageName
	
	for dev in $(ls ${loopdev}p*)
	do 
		partition=${dev##*/}
		
		if [ ! -d "/mnt_loop/$partition" ]; then			
			mkdir /mnt_loop/$partition
		fi
		mount $dev /mnt_loop/$partition
		
		#Get the rootfs image name.
		rootfs_bz2=$(ls $kernelImageDir/core-image-*.rootfs.tar.bz2)
		initramfs_cpio_gz=$(ls $kernelImageDir/core-image-uuidboot-initramfs*.cpio.gz)
		if [ ${partition##*p} == "2" ] || [ ${partition##*p} == "3" ]; then
			#copy the grub.cfg template
			pushd /mnt_loop/$partition/
			tar jxvf $kernalImageDir/$rootfs_bz2 
			#mkdir /mnt_loop/$partition/boot
			sync
			rsync $kernalImageDir/$initramfs_cpio_gz  /mnt_loop/$partition/boot/
			sync
			
		fi
	    pushd /
		sync
		sleep 1
		sync	
		umount $dev
	done
	
	sync
    losetup -d $loopdev

	
}

function set_bootloader()
{
	echo "Set bootloader, changing the grub.cfg"
	
	losetup $loopdev $diskImageName
	
	for dev in $(ls ${loopdev}p*)
	do 
		partition=${dev##*/}
		
		if [ ! -d "/mnt_loop/$partition" ]; then			
			mkdir /mnt_loop/$partition
		fi
		mount $dev /mnt_loop/$partition
		
		#Get the rootfs image name.
		
		
		if [ ${partition##*p} == "2" ]; then
			
			initramfs_cpio_gz2=$(ls /mnt_loop/$partition/boot/core-image-uuidboot-initramfs*.cpio.gz)
	        blkid2=$(blkid -s UUID -o value $dev)		
	        initramfs_cpio_gz2=${initramfs_cpio_gz2##*/}
		fi
	
		if [ ${partition##*p} == "3" ] ; then
			
			initramfs_cpio_gz3=$(ls /mnt_loop/$partition/boot/core-image-uuidboot-initramfs*.cpio.gz)
			blkid3=$(blkid -s UUID -o value $dev)
			initramfs_cpio_gz3=${initramfs_cpio_gz3##*/}
		fi
		
		sync
		sleep 1
		sync		
	done
	
	echo "$initramfs_cpio_gz2" and "$initramfs_cpio_gz3" and  "$blkid2" and "$blkid3"
	
	for dev in $(ls ${loopdev}p*)
	do 
		partition=${dev##*/}
		if [ ${partition##*p} == "1" ]; then
			sed "s/core-image-uuidboot-initramfs-changeling-hypervisor_1.cpio.gz/$initramfs_cpio_gz2/g" /mnt_loop/$partition/boot/grub/grub.cfg.template > /mnt_loop/$partition/boot/grub/grub.cfg.template1
			sync
			sed "s/core-image-uuidboot-initramfs-changeling-hypervisor_2.cpio.gz/$initramfs_cpio_gz3/g" /mnt_loop/$partition/boot/grub/grub.cfg.template1 > /mnt_loop/$partition/boot/grub/grub.cfg.template2	
			sync
			sed "s/86413256-371e-4c95-b8ea-9e583aa6a2cc/$blkid2/g" /mnt_loop/$partition/boot/grub/grub.cfg.template2 > /mnt_loop/$partition/boot/grub/grub.cfg.template3
			sync
			sed "s/2c753ace-5563-4993-8917-ca8ddc485b3f/$blkid3/g" /mnt_loop/$partition/boot/grub/grub.cfg.template3 > /mnt_loop/$partition/boot/grub/grub.cfg
			sync
			rm /mnt_loop/$partition/boot/grub/grub.cfg.template*
			tail -50 /mnt_loop/$partition/boot/grub/grub.cfg
		fi
		
		umount $dev
	done

	sync
    losetup -d $loopdev
}



if [ $# -lt 4 ] ;then
	echo "the argument number: $# , but this script take at leat 4 argument, see usage"
    usage
	exit 1
fi

#parse the option and parameters
while getopts :s:n:t:k: opt
do
   case $opt in 
	s)			
		echo "Vm disk size:$OPTARG"
		imageSize=$OPTARG;;
	n) 		
		echo "Vm disk image name:$OPTARG"
		diskImageName=$OPTARG;;
	t) 		
		echo "Vm disk image type:$OPTARG"
		imageType=$OPTARG;;
	k) 
		echo "Kernel image base DIR:$OPTARG"
		kernelImageDir=$OPTARG;;
	\?)	
		echo "Unknown params:, exiting! $OPTARG"
		usage
		exit 1;;
	esac
done

#create the disk image .img, only raw is support for now.
echo "creating the qemu image: $diskImageName"
qemu-img create -f $imageType $diskImageName $imageSize

if [ ! -f "$diskImageName" ]; then
    echo "qemu-img create disk image failed!"
    exit 2;
fi
echo "Successfully create disk image:"$diskImageName"!"


for loopdev in $(ls  /dev/loop?)
do 
	loopdev_in_use=$(losetup -a|grep $loopdev)
	if [ -z "$loopdev_in_use" ]; then	
		break
	else
		echo "loop device :" $loodev "is in use!"
	fi
done
echo "Find available loop device:"$loopdev"!"

# create the partition and make the file system
setup_disk
install_grub2
install_kernel
set_bootloader
#launch the VM
qemu-system-x86_64 -m 4096 -curses -hda $diskImageName	 -enable-kvm



    
#!/bin/bash

DUAL_CFV=0
while getopts d OPTION
do
     case $OPTION in
         d)
	DUAL_CFV=1 ;;
     esac
done

function launch_image()
{
	src_img_base=$1
	src_img=$1.qcow2
	dst_img_base=$2
	dst_img=$2.qcow2

	if [ ! -f /var/lib/libvirt/images/${dst_img} ]; then
        	echo sudo cp ${src_img} /var/lib/libvirt/images/${dst_img}
        	sudo cp $src_img /var/lib/libvirt/images/${dst_img}
	fi

	if [ "$src_img_base" != "$dst_img_base" ]; then
		echo "sed -e 's/$src_img_base/${dst_img_base}/g' ${src_img_base}.xml > ${dst_img_base}.xml" > /tmp/sed.script
		sh /tmp/sed.script
	fi

	sudo virsh define ${dst_img_base}.xml

	sudo virsh start ${dst_img_base}
	
}


shift $(expr $OPTIND - 1 )

if [ "$1" == "" ]; then
	echo "$0 [-d] qcow_file"
	exit 1
fi

qcow_base=${1%.*}


if [ ! -f $1 ] || [ ! -f ${qcow_base}.xml ]; then
	echo "$1 or ${qcow_base}.xml missing"
	exit 1
fi

if [ $DUAL_CFV == 1 ]; then
	launch_image $qcow_base ${qcow_base}-1
	launch_image $qcow_base ${qcow_base}-2
else
	launch_image $qcow_base $qcow_base
fi

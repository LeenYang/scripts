#!/bin/bash

IDE=1
SATA=2
SCSI=3

mode=$IDE

while getopts isS OPTION
do
     case $OPTION in
         s)
	 mode=$SATA ;;
	 i)
	 mode=$IDE ;;
	 S)
	 mode=$SCSI ;;
     esac
done

shift $(expr $OPTIND - 1 )

IMG=$1

case $mode in
  $IDE)
      echo "Running in IDE mode"
      echo "sudo qemu-system-x86_64 -m 4096 -curses -hda $IMG  -enable-kvm -nographic"
      sudo qemu-system-x86_64 -m 4096 -curses -hda $IMG  -enable-kvm -nographic
      ;;
  $SATA)
      echo "Running in SATA mode"
      echo "sudo qemu-system-x86_64 -m 4096 -curses \
            -device ich9-ahci,id=ahci \
            -device ide-drive,drive=sata_disk,bus=ahci.0 \
            -drive id=sata_disk,file=$IMG,if=none  \
            -enable-kvm -nographic"
      sudo qemu-system-x86_64 -m 4096 -curses \
            -device ich9-ahci,id=ahci \
            -device ide-drive,drive=sata_disk,bus=ahci.0 \
            -drive id=sata_disk,file=$IMG,if=none  \
            -enable-kvm -nographic
      ;;
  $SCSI)
      echo "Running in SCSI mode"
      echo "sudo qemu-system-x86_64 -m 4096 -curses \
            -device virtio-scsi-pci,id=scsi \
            -device scsi-hd,drive=scsi_disk \
            -drive if=none,id=scsi_disk,file=$IMG \
            -enable-kvm -nographic"
      sudo qemu-system-x86_64 -m 4096 -curses \
            -device virtio-scsi-pci,id=scsi \
            -device scsi-hd,drive=scsi_disk \
            -drive if=none,id=scsi_disk,file=$IMG \
            -enable-kvm -nographic

esac

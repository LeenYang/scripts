#!/bin/bash

echo "$0 -- ($#:$*)"
FULL_RESTART=${2:-false}


if [ $# == 0 ]; then
    echo "usage -- $0 <primary_vm> <full_restart> "
    echo "         primary_vm = primary vm to install (required)" 
    echo "         full_restart = true|false (default == false)"
    echo ""
    exit 1
fi
echo "FULL_RESTART: $FULL_RESTART"


PROFILE_FILE=/mnt/spirent/hypervisor/conf/activeprofile
if [ -e $PROFILE_FILE ]; then 
    PROFILE=$(cat $PROFILE_FILE) 

    if [ -z $PROFILE ]; then 
	echo "NULL Profile" 
        exit 1
    else
	echo "Using activeprofile:'$PROFILE'" 
        echo -n "Using Activevm:"; cat /mnt/spirent/chassis/local/activevm
    fi
fi 

cardinfo_control.py -g0 -i 

#set -x

L4L7VM=${1-l4l7Vm-4.70.9000.tgz}

L4L7_PKG=${L4L7VM/l4l7*-}
L4L7_VER=${L4L7_PKG/.tgz}

L4L7_LXC=l4l7lxc-$L4L7_VER.tgz
L4L7_FULLVM=l4l7Vm-$L4L7_VER.tgz 

L4L7_DIR=$(dirname ~/$L4L7VM)

echo "***** Installing using L4L7_DIR:$L4L7_DIR, L4L7_LXC:$L4L7_LXC, L4L7_FULLVM:$L4L7_FULLVM" 

mkdir -p /mnt/spirent/hypervisor/pkgs

# remove what ever is there. 

rm -f /mnt/spirent/hypervisor/pkgs/l4l7*.tgz 
if [ -e ${L4L7_DIR}/${L4L7_LXC} ] ; then 
    ln -sfnv ${L4L7_DIR}/${L4L7_LXC} /mnt/spirent/hypervisor/pkgs/${L4L7_LXC}
fi 

if [ -e ${L4L7_DIR}/${L4L7_FULLVM} ]; then 
    ln -sfnv ${L4L7_DIR}/${L4L7_FULLVM} /mnt/spirent/hypervisor/pkgs/${L4L7_FULLVM}
fi 

echo "Disable chassis restart deamon..." 
/mnt/spirent/hypervisor/script/initscripts/admin/admin.py recovery chassis disable

lxc_chassis=$(grep -l 'lxc' /mnt/spirent/hypervisor/active/chassis-*/chassis-0-libvirt.xml) 
#lxc_chassis=$(ps ax | grep '/usr/lib64/libvirt/libvirt_lxc --name chassis-0' | grep -v 'grep' ) 

if [ "$lxc_chassis" != "" ]; then 
    lxc_chassis=$(virsh -c lxc:// list | egrep 'chassis-0') 
    echo "**** WARNING: lxc_chassis:'$lxc_chassis' -- doing full restart..." 
    #virsh -c lxc:// stop chassis-0
    #virsh -c lxc:// destroy chassis-0
    FULL_RESTART=true 
fi 

if [ $FULL_RESTART == 'true' ]; then 
    spirent stop 
    sleep 3 
else 
    pkgmgr stop all
    sleep 5 
    pkgmgr deactivate all
    sleep 10
fi 

# twice to make sure lxc mounts are cleared. 
#pkgmgr deactivate all 

#pkgmgr remove all
rm -rf /mnt/spirent/hypervisor/install/l4l7*
rm -rf /mnt/spirent/hypervisor/active/l4l7*
rm -rf /mnt/spirent/data/l4l7lxc/slot-*
rm -rf /mnt/spirent/data/l4l7Vm/slot-*

echo "***** Installing new packages: ${L4L7_LXC}, ${L4L7_FULLVM}"

if [ -e /mnt/spirent/hypervisor/pkgs/${L4L7_LXC} ]; then 
    pkgmgr install /mnt/spirent/hypervisor/pkgs/${L4L7_LXC}
fi 

if [ -e /mnt/spirent/hypervisor/pkgs/${L4L7_FULLVM} ]; then 
    pkgmgr install /mnt/spirent/hypervisor/pkgs/${L4L7_FULLVM}
fi 

rm -rf /mnt/spirent/data/L4L7VM/slot-*
rm ~/.ssh/known_hosts

echo "***** Restarting with packages: ${L4L7_LXC}, ${L4L7_FULLVM}, lxc_chassis:$lxc_chassis"
# only need to start if chassis isn't running. 

if [ "$lxc_chassis" != ""  ]; then 
    # lxc chassis
    #
    lxc_chassis_running=$(virsh -c lxc:// list | grep 'chassis-0' | grep 'running' ) 
    if [ "$lxc_chassis_running" != "" ]; then 
        echo "lxc chassis ----- Doing launhcer... ($lxc_chassis_running)" 
        /mnt/spirent/hypervisor/script/initscripts/launcher/Launcher.py
    else
        echo "lxc chassis ----- Doing full restart..." 
        rm -f /mnt/spirent/hypervisor/conf/cardinfo.conf 
        spirent start 
    fi 
else 
    # fullVM chassis
    #
    fullvm_chassis_running=$(virsh list | grep 'chassis-0' | grep 'running' ) 
    if [ "$fullvm_chassis_running" != "" ]; then 
        echo "fullVm chassis ----- Doing launhcer... ($fullvm_chassis_running)" 
        /mnt/spirent/hypervisor/script/initscripts/launcher/Launcher.py
    else
        echo "fullVm chassis ----- Doing full restart..." 
        rm -f /mnt/spirent/hypervisor/conf/cardinfo.conf 
        spirent start 
    fi 
fi 

# restart check deamon. 
#echo "Re-enable chassis restart deamon..." 
#/mnt/spirent/hypervisor/script/initscripts/admin/admin.py recovery chassis enable  

echo "************* done installing ${L4L7VM} ****************"

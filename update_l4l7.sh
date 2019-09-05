#!/bin/bash

# exit when any command fails
set -e


usage()
{
	echo -e "\n Usage: $0 -n <newpackage> -g <portgroup number> 
	 Assume the new l4l7 package in in current directory. 	
	 \t -o  the old package currently is running.
	 \t -n  the new package to which it is going to upgrade
	 \t -g  the ccpu id / port group id to upgrade."
}

if [ $# -ne 4 ]; then
   echo "You have to input 4 argument!"
   usage
   exit
fi

OLD_PACKAGE=""
NEW_PACKAGE=""
PG_NUM=1

while getopts "o:n:g:" OPTION; do
    case $OPTION in
    n)
        NEW_PACKAGE=$OPTARG
        ;;
    g)
        COLOR=$OPTARG
        ;;
    *)
        echo "Incorrect options provided"
        usage
        exit 1
        ;;
    esac
done

eval "pkgmgr status | tee  ~/tmp_pkgmgr.txt"

# the port numbers in the portgroup N is usually N-1 and N
OLD_PACKAGE="$(grep "Ports: $((PG_NUM-1)) $PG_NUM" ~/tmp_pkgmgr.txt)"

OLD_PACKAGE="$(cut -d' ' -f1 <<< "$OLD_PACKAGE")"

echo -e "\ndeactivate the $OLD_PACKAGE"
eval "pkgmgr deactivate $OLD_PACKAGE"

echo -e "\ninstall package $NEW_PACKAGE"
eval "pkgmgr install ~/$NEW_PACKAGE"

echo -e "\nactivate new package ${NEW_PACKAGE%.*} on port group ${PG_NUM}"
eval "pkgmgr activate ${NEW_PACKAGE%.*} /tmp/launcher-${PG_NUM}.profile"

eval "pkgmgr status"



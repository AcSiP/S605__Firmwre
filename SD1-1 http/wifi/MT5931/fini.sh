#!/bin/sh
# Copyright (c) Nuvoton Technology Corp. All rights reserved.
# Description:	VT9271		module enable script
#		W.C  Lin	wclin@nuvoton.com

# Stop network service
PWD=`pwd`

ifconfig ap0 down
ifconfig wlan0 down

bloaded=`lsmod | grep p2p | awk '{print $1}'`
if [ "$bloaded" != "" ]; then
	rmmod p2p
fi

bloaded=`lsmod | grep wlan | awk '{print $1}'`
if [ "$bloaded" != "" ]; then
	if rmmod wlan; then  exit 0; fi
fi

exit 1

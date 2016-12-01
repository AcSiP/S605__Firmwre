#!/bin/sh
# Copyright (c) Nuvoton Technology Corp. All rights reserved.
# Description:	MT5931		module enable script
#		W.C  Lin	wclin@nuvoton.com

# startup network service

if [ -f "MT5931/WIFI_RAM_CODE" ]; then
	mkdir -p /etc/firmware/
	cp -f MT5931/WIFI_RAM_CODE /etc/firmware/
fi

if [ -f "MT5931/wlan.ko" ]; then
	bloaded=`lsmod | grep wlan | awk '{print $1}'`
	if [ "$bloaded" = "" ]; then 
		echo "insmod MT5931/wlan.ko"
		insmod MT5931/wlan.ko
	fi
fi

counter=0
while [ $counter != 10 ]; do
if ifconfig wlan0; then	break;	fi
       	echo "Waiting for Wifi dongle" > $MSGTOTERMINAL
	counter=`expr $counter + 1`
	sleep 1
done
if [ $counter = 10 ]; then exit 1; fi



if [ -f "MT5931/p2p.ko" ]; then
	bloaded=`lsmod | grep p2p | awk '{print $1}'`
	if [ "$bloaded" = "" ]; then
		echo "insmod MT5931/p2p.ko mode=1"
		insmod MT5931/p2p.ko mode=1
	fi
fi

counter=0
while [ $counter != 10 ]; do
if ifconfig ap0; then	break;	fi
       	echo "Waiting for Wifi dongle" > $MSGTOTERMINAL
	counter=`expr $counter + 1`
	sleep 1
done
if [ $counter = 10 ]; then exit 2; fi

exit 0

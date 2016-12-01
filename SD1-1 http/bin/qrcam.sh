#!/bin/sh

MSGTOTERMINAL=/dev/tty0
NETCONFIG_FILE=/tmp/zbar
PICT_FORMAT="RGBP 422P"

for i in $PICT_FORMAT
do
   while [ 1 ]; do
	echo -e "\033[H\033[J"  > $MSGTOTERMINAL
	/mnt/skyeye/bin/zbarcam --nodisplay --prescale=320x240 --v4l=1 --infmt=$i /dev/video0
	if [ $? != 0 ]; then
		break;
	fi

	echo -e "\033[1;33m" 	> $MSGTOTERMINAL
	cat $NETCONFIG_FILE	> $MSGTOTERMINAL
	echo -e "\033[m" 	> $MSGTOTERMINAL

	if grep DEVICE $NETCONFIG_FILE; then

        if grep CHIPSET $NETCONFIG_FILE; then

        if grep BOOTPROTO $NETCONFIG_FILE; then

        if grep IPADDR $NETCONFIG_FILE; then

        if grep GATEWAY $NETCONFIG_FILE; then

        if grep NETWORK_TYPE $NETCONFIG_FILE; then

        if grep SSID $NETCONFIG_FILE; then

        if grep AUTH_MODE $NETCONFIG_FILE; then

	if grep ENCRYPT_TYPE $NETCONFIG_FILE; then

		exit 0;

	fi; fi; fi; fi; fi; fi; fi; fi; fi;

   done
done

exit 1

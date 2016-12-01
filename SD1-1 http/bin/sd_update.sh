#!/bin/sh

UPGRADEPATH=/mnt/sdcard

if [ -f $UPGRADEPATH"/SkyEye.fw" ]; then 

	echo "To verify firmware..." > $MSGTOTERMINAL
	cp -a 	/mnt/skyeye/bin/mtdtool		/usr
	/usr/mtdtool chksum $UPGRADEPATH"/SkyEye.fw" > /dev/null
	RetCode=$?

	if [ $RetCode == 0 ]; then
                echo "Verified successfully!" > $MSGTOTERMINAL
		sync
		echo "Backup configuration..." > $MSGTOTERMINAL
		cp -a /mnt/skyeye/etc/		/tmp/etc_bk
		umount /mnt/nand1-2

                echo "To flash firmware..." > $MSGTOTERMINAL
		mtdtool flash $UPGRADEPATH"/SkyEye.fw"
                RetCode=$?
                if [ $RetCode == 0 ]; then
                        echo "To restore configuration..." > $MSGTOTERMINAL
		        mtdskyeye=`awk -F " " '/'"UserData_1"'/{print $1}' /proc/mtd`
		        mtdskyeye=`echo $mtdskyeye | sed "s/://"`
		        mtdskyeyeblock=`echo $mtdskyeye | sed "s/mtd/mtdblock/"`

		        mount -t jffs2 /dev/$mtdskyeyeblock /mnt/nand1-2
			cp	-a	/tmp/etc_bk/*	/mnt/skyeye/etc/
			sync

			echo "To reboot..." > $MSGTOTERMINAL
			while [ 1 ]; do
				platform=`ls /sys/devices/platform/*-clk/clock`
				echo "pr" > $platform
				sleep 5
			done
		else
                        echo "Flash fail"	 > $MSGTOTERMINAL
			exit 3
		fi
	else
		echo "Verify fail"	 > $MSGTOTERMINAL
		exit 2
	fi
else
	echo "Can't found SkyEye.fw SD card"        > $MSGTOTERMINAL
	exit 1
fi
exit 0

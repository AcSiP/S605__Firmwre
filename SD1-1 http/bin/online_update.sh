#!/bin/sh

UPDATE_FW=/tmp/update


mtdskyeye=`awk -F " " '/'"Reserved"'/{print $1}' /proc/mtd`
mtdskyeye=`echo $mtdskyeye | sed "s/://"`
mtdskyeyeblock=`echo $mtdskyeye | sed "s/mtd/mtdblock/"`

if [ -f "/mnt/skyeye/update" ]; then

	echo "Upgrading ..." > $MSGTOTERMINAL

	mkdir $UPDATE_FW

	mount -t jffs2 /dev/$mtdskyeyeblock $UPDATE_FW

	if [ $? = 0 ]; then

	        if [ -f $UPDATE_FW"/SkyEye.fw" ]; then
	                # Backup setting
			echo "Backup Config..." > $MSGTOTERMINAL
	                cp -a /mnt/skyeye/etc/        /tmp/etc_bk
	                umount /mnt/nand1-2

        	        # Flash
	                echo "Programming FW..." > $MSGTOTERMINAL
			#Have http boundary
		        mtdtool flash $UPDATE_FW"/SkyEye.fw"
			ret=$?
				
	                echo "Restoring Config..." > $MSGTOTERMINAL
	        	mount -t jffs2 /dev/mtdblock2 /mnt/nand1-2
			# restore configuration
			cp -a	/tmp/etc_bk/*	/mnt/skyeye/etc/
	
	               	sync
			if [ $ret == 0 ]; then
			        platform=`ls /sys/devices/platform/*-clk/clock`
				echo "pr" > $platform
				sleep 5
			fi
	        fi
	fi
fi

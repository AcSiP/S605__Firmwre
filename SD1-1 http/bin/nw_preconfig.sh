#!/bin/sh

# To check connected with PC
insmod /usr/mtdram.ko

mtdram=`awk -F " " '/'"mtdram test device"'/{print $1}' /proc/mtd`
mtdram=`echo $mtdram | sed "s/://"`
mtdramblock=`echo $mtdram | sed "s/mtd/mtdblock/"`
EXPORTPATH=/tmp/exportdisk

if [ $mtdramblock != "" ]; then

	  while [ 1 ]; do

                echo "Now, format ramdisk to FAT12..." > $MSGTOTERMINAL
		# Fixed issue that window XP free space is zero
		/mnt/skyeye/bin/mkdosfs	-c -F 12 	/dev/$mtdramblock
                if [ $? != 0 ]; then 
			echo "To format FAT12 Failure..."	> $MSGTOTERMINAL
			break; 
		fi
		
                if [ ! -d $EXPORTPATH ]; then mkdir -p $EXPORTPATH; fi

                mount -t vfat -o noatime,shortname=mixed,utf8   /dev/$mtdramblock       $EXPORTPATH
                if [ $? = 0 ]; then  
			mkdir -p	$EXPORTPATH/etc
			cp /tmp/etc/*_config		$EXPORTPATH/etc
                        cp /tmp/etc/puncher.conf	$EXPORTPATH/etc
			sync
			umount 				$EXPORTPATH
	                if [ $? != 0 ]; then
	                       echo "To umount ramdisk failure ..."     > $MSGTOTERMINAL
        	               break;
                	fi
		else
                        echo "To mount ramdisk failure ..."     > $MSGTOTERMINAL
			break;  
		fi

                echo "To export RamDisk..." > $MSGTOTERMINAL
	
		if grep 2.6.17.14 /proc/version; then
                   /mnt/skyeye/bin/skyeye_mass     /dev/$mtdramblock &
                   /mnt/skyeye/bin/usbcabledet 1 5
                   if [ $? = 0 ]; then
                        /mnt/skyeye/bin/usbcabledet 0 0
                   else
                        killall skyeye_mass
                        break;
                   fi
		else
	           insmod /usr/g_file_storage.ko file=/dev/$mtdramblock stall=0 removable=1
		   /mnt/skyeye/bin/usbcabledet 1 3
		   if [ $? = 0 ]; then
			/mnt/skyeye/bin/usbcabledet 0 0
		   else
			break;
		   fi
		fi

	        mount -t vfat -o noatime,shortname=mixed,utf8	/dev/$mtdramblock	$EXPORTPATH
		if [ $? = 0 ]; then
                        cp -f $EXPORTPATH/etc/*_config		/tmp/etc/
                        cp -f $EXPORTPATH/etc/puncher.conf     	/tmp/etc/puncher.conf
			if [ -f /tmp/etc/wpa.conf ]; then
				rm -f /tmp/etc/wpa.conf
			fi
                        if [ -f /tmp/etc/hostapd.conf ]; then
	                        rm -f /tmp/etc/hostapd.conf
			fi
                        sync
			umount 				$EXPORTPATH
                        if [ $? != 0 ]; then
                               echo "To umount ramdisk failure ..."     > $MSGTOTERMINAL
                        fi
			break;
		else
	                echo "Mount Ramdisk to system failure ..." > $MSGTOTERMINAL
			break;
		fi
		

           done
	
fi

if grep 2.6.35.4 /proc/version; then
	rmmod -f g_file_storage
fi

rmmod -f mtdram

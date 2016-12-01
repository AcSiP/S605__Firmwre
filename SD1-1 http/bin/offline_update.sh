#!/bin/sh

insmod /usr/mtdram.ko

mtdram=`awk -F " " '/'"mtdram test device"'/{print $1}' /proc/mtd`
mtdram=`echo $mtdram | sed "s/://"`
mtdramblock=`echo $mtdram | sed "s/mtd/mtdblock/"`

UPGRADEPATH=/tmp/update

if [ $mtdramblock != "" ]; then

    while [ 1 ]; do

	while [ 1 ]; do


                echo "Now, format ramdisk to FAT12..." > $MSGTOTERMINAL
                # Fixed issue that window XP free space is zero
                /mnt/skyeye/bin/mkdosfs -c -F 12        /dev/$mtdramblock

                echo "Please plug in USB cable to board..." > $MSGTOTERMINAL
                if grep 2.6.17.14 /proc/version; then
	                /mnt/skyeye/bin/usbcabledet     1
			echo "To export RamDisk..." > $MSGTOTERMINAL
			/mnt/skyeye/bin/skyeye_mass     /dev/$mtdramblock
		else
		        bloaded=`lsmod | grep g_file_storage | awk '{print $1}'`
		        if [ "$bloaded" = "" ]; then
			    insmod /usr/g_file_storage.ko file=/dev/$mtdramblock stall=0 removable=1
			fi
	                /mnt/skyeye/bin/usbcabledet     1
			echo "To export RamDisk..." > $MSGTOTERMINAL
	                /mnt/skyeye/bin/usbcabledet     0
                fi

                if [ ! -d $UPGRADEPATH ]; then mkdir $UPGRADEPATH; fi
                mount -t vfat -o noatime,shortname=mixed,utf8   /dev/$mtdramblock       $UPGRADEPATH
                if [ $? = 0 ]; then
                        break;
                else
                        echo "Mount Ramdisk to system failure ..." > $MSGTOTERMINAL
                fi
	done
	
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
				break
			else
	                        echo "Flash fail"	 > $MSGTOTERMINAL
			fi
		else
			echo "Verify fail"	 > $MSGTOTERMINAL
		fi
	else
                        echo "Can't found SkyEye.fw in ramdisk"        > $MSGTOTERMINAL
			echo "Stop offline updating procedure? "
			echo "Press reset key on board.."
			echo "  "
        fi
	
	umount $UPGRADEPATH

  done

  echo "To reboot..." > $MSGTOTERMINAL

  platform=`ls /sys/devices/platform/*-clk/clock`
  echo "pr" > $platform
  sleep 5

fi

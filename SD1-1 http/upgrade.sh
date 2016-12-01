#!/bin/sh

bMounted=`df | grep /mnt/nand1-1 | awk '{print $1}'`

if [ "$bMounted" == "/dev/sda1" ] || [ "$bMounted" == "/dev/mmcblk0p1" ]; then
	echo "Backup current firmware ..."
	# Backup current firmware if necessary
	#if [ -d $1/backup_fw ] ; then
	#	rm -rf $1/backup_fw
	#fi
	
	#mkdir $1/backup_fw
	#cp -af /mnt/nand1-1/* $1/backup_fw/
	
	# Backup current config if necessary
	#mv	/mnt/nand1-1/etc	/tmp
	
	echo "Upgrading ...."
	mv $1/skyeye_upgrade.zip $1/_skyeye_upgrade.zip
	unzip -o $1/_skyeye_upgrade.zip -d /mnt/nand1-1
	
	if [ $? == 0 ] ; then
		echo "Checking files...."
		# Check updated firmware files or write extra upgrade script here
		#mv	-f /tmp/etc/*.conf /mnt/nand1-1/etc/
		
		sync
		
		#reboot
		platform=`ls /sys/devices/platform/*-clk/clock`
		echo "pr" > $platform
	fi
fi

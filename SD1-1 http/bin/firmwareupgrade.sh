#!/bin/sh

# Copyright (c) Nuvoton Technology Corp. All rights reserved.

#if [ ! "$REQUEST_METHOD" == "POST" ]; then exit 1; fi
#if [ ! $CONTENT_LENGTH -gt 0 ]; then exit 1; fi

UploadFw=/tmp/update
LockFile=/tmp/skyeye.lock

RetCode=99

if [ ! -f "$LockFile" ]; then
	#To lock
	echo "0" > $LockFile
	sync

	if [ ! -f "/mnt/nand1-1/conprog.bin" ]; then
#========================== SPI ==========================
		UD=`df | grep -r $UploadFw | awk '{print $6}'`
		
		if [ "$UD" == "$UploadFw" ]; then 
			/bin/umount  $UploadFw	
		else
			if [ -d $UploadFw ]; then rm -rf $UploadFw; fi
			mkdir -p $UploadFw
		fi

		mtdskyeye=`awk -F " " '/'"Reserved"'/{print $1}' /proc/mtd`
		mtdskyeye=`echo $mtdskyeye | sed "s/://"`
		mtdnumber=`echo $mtdskyeye | sed "s/mtd//"`
	        if grep 2.6.17.14 /proc/version; then
			mtdnumber=`expr $mtdnumber \* 2`
		else
			mtdnumber=`expr $mtdnumber \* 1`
		fi
		/usr/sbin/flash_eraseall -j /dev/mtd$mtdnumber > /dev/null
		
		if [ $? == 0 ]; then
			mtdskyeyeblock=`echo $mtdskyeye | sed "s/mtd/mtdblock/"`
			/bin/mount -t jffs2 /dev/$mtdskyeyeblock $UploadFw
			RetCode=$?
		fi
#========================== SPI ==========================
	else
#========================== NAND ==========================
		if [ -d $UploadFw ]; then
			rm -rf $UploadFW
		fi

		ln -s /mnt/nand1-2/ $UploadFw
		sync
		RetCode=0
#========================== NAND ==========================
	fi
fi

exit $RetCode

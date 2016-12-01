#!/bin/sh
#
# Copyright (c) 2013 Nuvoton Technology Corp. All rights reserved.
#

TS=`cat /proc/uptime | awk '{print $1}'`
echo -e "\033[1;33m[$TS] Starting msloader.\033[m"

if [ "$1" != "" ] ; then
	PLUGIN_LIBS_PATH=$1
else
	PLUGIN_LIBS_PATH="/mnt/skyeye/lib/skyeye"
fi

if [ "$2" != "" ] ; then
	CONF_PATH=$2
else
	CONF_PATH="/mnt/skyeye/etc"
fi

DEF_CONF_PATH=$CONF_PATH"/factory"

if [ ! -f "$CONF_PATH"/msloader.conf ] ; then
	if [ -f "$CONF_PATH"/_msloader.conf ] ; then
		echo "Loader is disabled! Exit"
		exit 0
	fi
	
	if [ -f "$DEF_CONF_PATH"/msloader.conf ] ; then
		echo "Cannot find valid loader configuration. Load factory default..."
		cp "$DEF_CONF_PATH"/msloader.conf "$CONF_PATH"
	else
		echo "Failed to load valid loader configuration! Exit"
		exit 1
	fi
fi

#CONF_FILE_LIST=`ls "$DEF_CONF_PATH"`
CONF_FILE_LIST="alarm.conf puncher.conf .skyeye.user"

for CONF_FILE in $CONF_FILE_LIST
do
	if [ ! -f "$CONF_PATH"/"$CONF_FILE" ] ; then
		echo "Cannot find valid "$CONF_FILE". Load factory default..."
		cp "$DEF_CONF_PATH"/"$CONF_FILE" "$CONF_PATH"
	fi
done

# Create symbolic link with $PHY_REC_PATH to save record files
PHY_REC_PATH=`awk -F"[=#]" '$1 == "Phyical_Record_Path"{ print $2}' "$CONF_PATH"/msloader.conf`
if [ "$PHY_REC_PATH" == "AUTO" ] ; then
	PHY_REC_PATH=`df | awk 'NR > 1 && max < $2 { max = $2; max_stor_path = $6; } END { print max_stor_path }'`
else
	if [ ! -d "$PHY_REC_PATH" ] ; then
		# If defined record path is not exist, try to create
		mkdir -p "$PHY_REC_PATH"
		sync
	fi
fi

if [ -d "$PHY_REC_PATH" ] ; then
	if [ -d /mnt/rec_folder ] ; then
		rm /mnt/rec_folder
	fi

	ln -s "$PHY_REC_PATH" /mnt/rec_folder
	ln -s /mnt/rec_folder /tmp/media
fi

# Update localtime by TimeZone
TIME_ZONE=`awk -F"[=#]" '$1 == "Time_Zone"{ print $2}' "$CONF_PATH"/msloader.conf`
if [ "$TIME_ZONE" != "" ] ; then
	echo $TIME_ZONE > /etc/TZ
	hwclock -s
fi

# Mount ram disk for TS file output
if [ -f /mnt/skyeye/lib/skyeye/plugin_ts_writer.so ] ; then
	TS_OUTPUT_PATH=`awk -F"[=#]" '$1 == "TS_Output_Path"{ print $2}' "$CONF_PATH"/msloader.conf`
	if [ "$TS_OUTPUT_PATH" != "" ] ; then
		mkdir -p "$TS_OUTPUT_PATH"
		chmod 777 "$TS_OUTPUT_PATH"
		mkdosfs /dev/ram0
		mount /dev/ram0 "$TS_OUTPUT_PATH"
		cp /mnt/skyeye/htdocs/hls_stream.html "$TS_OUTPUT_PATH"/index.html
	fi
fi

PLUGIN_CONF_PATH=$CONF_PATH"/plugin"
DEF_PLUGIN_CONF_PATH=$DEF_CONF_PATH"/plugin"

if [ ! -d $PLUGIN_CONF_PATH ] ; then
	if [ -d "$DEF_PLUGIN_CONF_PATH" ] ; then
		echo "Cannot find valid plugin configuration. Load factory default..."
		cp -af "$DEF_PLUGIN_CONF_PATH" "$CONF_PATH"
	else
		echo "Failed to load valid plugin configuration! Exit"
		exit 1
	fi
fi

PLUGIN_LIST=`ls $PLUGIN_LIBS_PATH`
PLUGIN_LOAD_CNT="1"

for PLUGIN in $PLUGIN_LIST
do
	CONF_FILE=`echo $PLUGIN | awk -F. 'sub(/plugin_/,""){ print $1 }'`
	# Configuation file of enabled plugin has no prefix
	CONF_FILE_PATH=$PLUGIN_CONF_PATH"/"$CONF_FILE".conf"
	# Configuation file of disabled plugin has prefix with "_"
	_CONF_FILE_PATH=$PLUGIN_CONF_PATH"/_"$CONF_FILE".conf"
	
	if [ ! -f $CONF_FILE_PATH ] && [ ! -f $_CONF_FILE_PATH ] ; then
		if [ -f "$DEF_PLUGIN_CONF_PATH"/"$CONF_FILE".conf ] ; then
			echo "Cannot find valid configuration of "$CONF_FILE". Load factory default..."
			cp "$DEF_PLUGIN_CONF_PATH"/"$CONF_FILE".conf "$PLUGIN_CONF_PATH"
		fi
	fi
	
	# Only check and load enabled plugin
	if [ -f $CONF_FILE_PATH ] ; then
		SCRIPT=`awk -F"[=#]" '!/^($|#)/{ print $4 " " $2 }' "$CONF_FILE_PATH"`
		SCRIPT="-p \""$PLUGIN" "$SCRIPT"\" "
		EXEC_SCRIPT=$EXEC_SCRIPT$SCRIPT
		echo $SCRIPT
		
		PLUGIN_LOAD_CNT=`expr $PLUGIN_LOAD_CNT + 1`
	fi
done

if [ "$PLUGIN_LOAD_CNT" == "1" ] ; then
	echo "No plugin to load! Exit"
	exit 0
fi

export LD_LIBRARY_PATH="/mnt/skyeye/lib/skyeye:/mnt/skyeye/lib:$LD_LIBRARY_PATH:/mnt/usrlib"
export PATH="$PATH:/mnt/skyeye/bin"

SCRIPT=`awk -F"[=#]" '!/^($|#)/ && ($4 != ""){ print $4 " " $2 }' "$CONF_PATH"/msloader.conf`

eval "msloader "$SCRIPT" "$EXEC_SCRIPT" &"

THREAD_CNT="0"

# Check running thread count 
while [ "$THREAD_CNT" -lt "$PLUGIN_LOAD_CNT" ] ; do
	THREAD_CNT=`ps | grep -c "msloader "`
	sleep 1
done

echo Now msloader is running...

TS=`cat /proc/uptime | awk '{print $1}'`
echo -e "\033[1;33m[$TS] msloader done.\033[m"

sync
exit 0

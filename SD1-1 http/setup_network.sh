#!/bin/sh

export LD_LIBRARY_PATH="/mnt/skyeye/lib:$LD_LIBRARY_PATH"

PRJ_PATH=$1
NETCONFPATH="/tmp/etc/network_config"
ETHERNETCONFPATH="/tmp/etc/ethernet_config"
MOBILENETCONFPATH="/tmp/etc/mobilenet_config"
if [ -d $PRJ_PATH"/ethernet" ]; then ln -s $PRJ_PATH/ethernet 	/usr/ethernet; fi
if [ -d $PRJ_PATH"/mobilenet" ]; then ln -s $PRJ_PATH/mobilenet	/usr/mobilenet; fi
if [ -d $PRJ_PATH"/wifi" ]; 	then ln -s $PRJ_PATH/wifi 	/usr/wifi; fi
if [ -d $PRJ_PATH"/netplug" ]; then ln -s $PRJ_PATH/netplug   /usr/netplug; fi

# Open loopback interface for flv streamer to RTMP server
ifconfig lo up
ret=1

# =================== Ethernet/PPPoE =======================
if [ -d "/usr/ethernet" ]; then
        cd      /usr/ethernet
        if [ ! -f $ETHERNETCONFPATH ]; then
             if [ -f "/usr/ethernet/ethernet_config.default" ]; then
                     echo "Using default network configuration file." > $MSGTOTERMINAL
                     cp -a /usr/ethernet/ethernet_config.default     $ETHERNETCONFPATH
             fi
        fi
	./ethernet.sh
	ret=`expr $ret ** $?`
fi

# =================== MobileNet 3G/4G =======================
if [ -d "/usr/mobilenet" ]; then
        cd      /usr/mobilenet
        if [ ! -f $MOBILENETCONFPATH ]; then
             if [ -f "/usr/mobilenet/mobilenet_config.default" ]; then
                     echo "Using default network configuration file." > $MSGTOTERMINAL
                     cp -a /usr/mobilenet/mobilenet_config.default     $MOBILENETCONFPATH
             fi
        fi
	./mobilenet.sh start
	ret=`expr $ret ** $?`
fi

# =================== Networking setting   ===================
if [ -d "/usr/wifi" ]; then
    cd      /usr/wifi
    if [ ! -f $NETCONFPATH ]; then
	     if [ -f "/usr/wifi/network_config.default" ]; then
	             echo "Using default network configuration file." > $MSGTOTERMINAL
                     cp -a /usr/wifi/network_config.default 	$NETCONFPATH
		     sync
             fi
    fi


    if [ -f $NETCONFPATH ]; then

        WPS_TRIG_KEY_STR=`awk '{if ($1=="WPS_TRIG_KEY") {print $2}}' $NETCONFPATH`
        case "$WPS_TRIG_KEY_STR" in

        "POWER"|"power") #POWER
                WPS_TRIG_KEY=77
        ;;

        "HOME"|"home")   #HOME
		WPS_TRIG_KEY=19
        ;;

        "RIGHT"|"right") #RIGHT
                WPS_TRIG_KEY=13
        ;;

        "DOWN"|"down")   #DOWN
                WPS_TRIG_KEY=15
        ;;

        "UP"|"up")  	 #UP
                WPS_TRIG_KEY=14
        ;;

	*)
                echo "No valid WPS setting." > $MSGTOTERMINAL
                echo "Please define WPS key in config file." > $MSGTOTERMINAL
                echo "WPS PBC mode [Fail]." > $MSGTOTERMINAL
                WPS_TRIG_KEY=-99
	;;	
        esac

	if [ $WPS_TRIG_KEY != -99 ]; then

#	        echo "Enable QR viewer? Press <" $WPS_TRIG_KEY_STR "> key" > $MSGTOTERMINAL
#	        kpdin -t 2
#	        if [ $? = $WPS_TRIG_KEY ]; then
	             # WPS
#	             echo "Starting QR view." > $MSGTOTERMINAL
#	                /mnt/skyeye/bin/qrcam.sh
#	                if [ $? != 0 ]; then    exit 1; fi
#	                cp -a /tmp/zbar         $NETCONFPATH
#	                rm -f /tmp/etc/wpa.conf
#	                rm -f /tmp/etc/hostapd.conf
#	                sync
#	                echo "Save network configuration [OK]." > $MSGTOTERMINAL
#	        fi

        	echo "Enable WPS? Press <" $WPS_TRIG_KEY_STR "> key" > $MSGTOTERMINAL
        	kpdin -t 2
        	if [ $? = $WPS_TRIG_KEY ]; then
                	# WPS
                	echo "Starting WPS PBC mode." > $MSGTOTERMINAL
	                echo "Please press WPS button on AP" > $MSGTOTERMINAL
			if ./network.sh WPS PBC; then	
				# Todo check status at here
				echo "WPS PBC mode [OK]." > $MSGTOTERMINAL
			fi
	        else
	                echo "Configure network setting ..." > $MSGTOTERMINAL		        
                        if ./network.sh; then
				echo "Configure network successfully!!" > $MSGTOTERMINAL
				ret=`expr $ret ** $?`
			fi
	        fi
	fi

   fi

fi

#==============================================================================
#	Start Netplug or not
#==============================================================================
if [ -d "/usr/netplug" ]; then
        cd /usr/netplug
        ./netplugd.sh &
fi

exit $ret

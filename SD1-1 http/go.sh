#!/bin/sh

export LD_LIBRARY_PATH="/mnt/skyeye/lib:$LD_LIBRARY_PATH"
export PATH="`pwd`/bin:`pwd`/sbin:/mnt/nand1-1/wifi/:/usr/wifi:$PATH"
root_path=`pwd`

NETWORKLOGF="/tmp/.network.log"
NETCONFIG_FILE="/usr/wifi/network.sh"
STA_DEVICE=`awk -F= '{if ($1=="STA_DEVICE") {print $2}}' $NETCONFIG_FILE`

# To limit socket number
#echo 32        >       /proc/sys/net/ipv4/tcp_max_tw_buckets
#echo 1         >       /proc/sys/net/ipv4/tcp_tw_recycle
#echo 1         >       /proc/sys/net/ipv4/tcp_tw_reuse
#echo 20        >       /proc/sys/net/ipv4/tcp_fin_timeout
#echo 600       >       /proc/sys/net/ipv4/tcp_keepalive_time

export WIRELESS_MODE="`iwconfig $STA_DEVICE | grep SoftAP | awk '{print $3}'`"
export NETWORK_TYPE="`iwconfig $STA_DEVICE | grep Mode | awk '{FS=":"} {print $2}' | awk '{print $1}'`"

if [ -f "/mnt/skyeye/bin/mtdtool" ]; then
	cp -a /mnt/skyeye/bin/mtdtool /usr
fi

if [ -f /mnt/skyeye/etc/crtmpserver.lua ] ; then
	/mnt/skyeye/sbin/crtmpserver /mnt/skyeye/etc/crtmpserver.lua &
fi

echo "Starting msloader." > $MSGTOTERMINAL
./msloader_go.sh

exit 0

ClnScreen() {
	echo -e "\033[H\033[J"  > $MSGTOTERMINAL	
}

ProcessStatus() {
	PROCESSSET="msloader dnsmasq udhcpc puncher"
	ps > /tmp/.process.log
	for i in $PROCESSSET
	do
		ret=`cat /tmp/.process.log | grep $i | awk '{print $3}'`
		if [ "$ret" != "" ] ; then
			echo -e $i" \033[1;33m[OK]!\033[m" > $MSGTOTERMINAL
		else
			echo -e $i" \033[1;31m[FAIL]!\033[m" > $MSGTOTERMINAL
		fi
	done
}

NetworkStatus() {
	echo "[Host]         " `ifconfig $STA_DEVICE | grep inet | awk '{FS=":"} {print $2}' | sed 's/[^0-9\.]//g'` > $NETWORKLOGF
	echo "[GW]           " `route -n | awk '{ if ( $1=="0.0.0.0" ) {print $2} }'`  >> $NETWORKLOGF

	if [ "`route -n | awk '{ if ( $1=="0.0.0.0" ) {print $2} }'`" != "" ] ; then
		echo "[IGD]          " `upnpc -s | grep ExternalIPAddress | sed 's/[^0-9\.]//g'`  >> $NETWORKLOGF
	fi

	echo " "        >> $NETWORKLOGF
	echo "[SSID]         " `iwconfig $STA_DEVICE |grep ESSID | awk '{FS=":"} {print $2}' | awk '{print $1}'` >> $NETWORKLOGF
	echo "[Bitrate]      " `iwlist $STA_DEVICE rate|grep Current| awk '{FS=":"} {print $2}' | awk '{print $1}'` "Mbps" >> $NETWORKLOGF
	echo "[Channel]      " `iwlist $STA_DEVICE channel|grep Current| awk '{FS=":"} {print $2}' | awk '{print $1}'` "GHz" >> $NETWORKLOGF
}

SwitchVPOSTClk() {
       bVClk=$1
       if [ $bVClk = 0 ]; then
	      # Chagne VPOST_CKE in AHBCLK register to 0
	      nvtbitio -p 0xb0000204 -b 28 -v 0
              bVClk=1
       else
              # Chagne VPOST_CKE in AHBCLK register to 1
              nvtbitio -p 0xb0000204 -b 28 -v 1
              bVClk=0
       fi
       return $bVClk
}

ShowQRImage() {
	bQR=$1
	if [ $bQR = 0 ]; then
	      if [ ! -f "/tmp/qr.png" ]; then
                      if [ "$NETWORK_TYPE" == "Managed" ] && [ "$WIRELESS_MODE" != "SoftAP" ]; then #STATION MODE
                                NETIP=`upnpc -s | grep ExternalIPAddress | sed 's/[^0-9\.]//g'`
                                EXPORT=`cat /mnt/skyeye/etc/puncher.conf | grep ExternalPort | sed 's/[^0-9\.]//g'`
                                NETIP="$NETIP:$EXPORT"
                      else #adhoc
                                NETIP=`ifconfig $STA_DEVICE | grep inet | awk '{FS=":"} {print $2}' | sed 's/[^0-9\.]//g'`
                      fi
                      URL="http://$NETIP/SkyEye"
                      echo $URL
                      arm-none-linux-gnueabi-qrencode -s 4 -m 1 -o /tmp/qr.png $URL
                      sync
              fi
              png2fb -f /tmp/qr.png
              bQR=1
       else
              png2fb -h
              bQR=0
       fi
       usleep 100000
       return $bQR
}

ShowUptime() 
{
	uptime=$(cat /proc/uptime | awk '{print $1}' | sed 's/\.//')

	secuptime=`expr  $uptime / 100`

	seconds=`expr  $secuptime % 60`

	minutes=`expr $secuptime / 60 % 60`

	hours=`expr $secuptime / 60 / 60 % 24`

	days=`expr $secuptime / 60 / 60 / 24`

	echo "[Uptime] $days(D) $hours(H) $minutes(M) $seconds(S)" > $MSGTOTERMINAL
}

ShowInternetStatus()
{
        if ping -4 -c 1 -w 1 www.apple.com > /dev/null; then
		echo "[Internet status] OK."   > $MSGTOTERMINAL
	else
               	echo "[Internet status] Fail." > $MSGTOTERMINAL
	fi
}

ShowSVNVersion()
{
	if [ -f "/mnt/skyeye/htdocs/version.txt" ]; then
		SKY_VER=`cat "/mnt/skyeye/htdocs/version.txt" | grep "SkyEye"`
        	BSP_VER=`cat "/mnt/skyeye/htdocs/version.txt" | grep "BSP"`  
		echo "Version: $SKY_VER ($BSP_VER)"	> $MSGTOTERMINAL
	fi
}

bQRShow=0
bVPOSTCLK=0
echo " " > $MSGTOTERMINAL
echo " " > $MSGTOTERMINAL

PrintUsage() {
	SwitchVPOSTClk 1
        bVPOSTCLK=$?
        ShowUptime
        ShowInternetStatus
        ShowSVNVersion
        echo -e "\033[1;33m<UP>\033[mShow/Hide QR Code." > $MSGTOTERMINAL
        echo -e "\033[1;33m<DOWN>\033[mClean screen."       > $MSGTOTERMINAL
        echo -e "\033[1;33m<ENTER>\033[mShow network status" > $MSGTOTERMINAL
        echo -e "\033[1;33m<HOME>\033[mShow process status" > $MSGTOTERMINAL
        echo -e "\033[1;33m<POWER>\033[mEnable/Disable VPOST clock" > $MSGTOTERMINAL
        echo " " > $MSGTOTERMINAL
}

PrintUsage
KEY_POWER=77

if [ -f /usr/fa92_devmem.ko ] ; then
	KEY_UP=19
	KEY_DOWN=13
	KEY_LEFT=2
	KEY_RIGHT=1
	KEY_HOME=14
	KEY_ENTER=15
fi

if [ -f /usr/fa93_devmem.ko ] ; then
	KEY_UP=14
	KEY_DOWN=15
	KEY_LEFT=1
	KEY_RIGHT=2
	KEY_HOME=19
	KEY_ENTER=13
fi

while [ 1 = 1 ]; do
	kpdin -t 60
	case $? in
	$KEY_RIGHT) # Reset factory
		SwitchVPOSTClk 1
		ClnScreen
		echo -e "\033[mPress <ENTER> to restore default setting or others to quit" > $MSGTOTERMINAL
		
		while [ 1 = 1 ]; do
			kpdin -t 60
			case $? in
			$KEY_ENTER)
				echo "Restore default ..."
				echo -e "\033[mRestore system default and reboot to take effect" > $MSGTOTERMINAL
				rm -rf /mnt/skyeye/etc/plugin
				rm /mnt/skyeye/etc/network_config
				rm /mnt/skyeye/etc/*.conf
				#rm -rf /mnt/skyeye/etc/wpa.conf
				#rm -rf /mnt/skyeye/etc/hostapd.conf
				#rm -rf /mnt/skyeye/etc/alarm.conf
				#rm -rf /mnt/skyeye/etc/puncher.conf
				sync
				reboot
			;;
			$KEY_RIGHT)
			;;
			*)
				break
			;;
			esac
		done
		
		ClnScreen
		SwitchVPOSTClk 0
	;;
	$KEY_HOME)  # PROCESS Status
		ClnScreen
		PrintUsage
		ProcessStatus
	;;

	$KEY_ENTER)  # NETWORK/IPV4/ROUTING
		ClnScreen
		echo "Wait ... "        > $MSGTOTERMINAL
		
		NetworkStatus

		ClnScreen
		PrintUsage
		cat $NETWORKLOGF> $MSGTOTERMINAL
	;;
	
	$KEY_DOWN)  # Clear screen
		ClnScreen
		PrintUsage
	;;

	$KEY_UP)	# Show QR CODE
		SwitchVPOSTClk 1
		bVPOSTCLK=$?

		ShowQRImage $bQRShow
		bQRShow=$?
	;;

	$KEY_POWER)	# Switch VPOST clock
		SwitchVPOSTClk $bVPOSTCLK
		bVPOSTCLK=$?
	;;

	*)
		SwitchVPOSTClk 0
		bVPOSTCLK=$?
	;;

	esac
	usleep 300000
done

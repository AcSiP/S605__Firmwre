#!/bin/sh
# Copyright (c) Nuvoton Technology Corp. All rights reserved.
# Description:	WiFi startup script
# Version:	2012-10-12	first release version
#		W.C  Lin

if [ -z "$MSGTOTERMINAL" ]; then 
	export MSGTOTERMINAL="/dev/ttyS1";
fi

NETCONFIG_FILE=/tmp/etc/network_config

WPA_CONF_FILE=/tmp/wpa.conf
AP_CONF_FILE=./p2p.conf.default
if [ ! -f $NETCONFIG_FILE ]; then
        echo "Can't find $NETCONFIG_FILE"
        exit 1
fi

if [ -f $WPA_CONF_FILE ]; then
	CTRL_INTERFACE=`awk -F= '{if ($1=="ctrl_interface") {print $2}}' $WPA_CONF_FILE`
else
	CTRL_INTERFACE=`awk -F= '{if ($1=="ctrl_interface") {print $2}}' $AP_CONF_FILE`	
fi

# set DEVICE to wlan0
STA_DEVICE=wlan0
STA_CHIPSET=MT5931
# set BOOTPROTO to DHCP/STATIC
STA_BOOTPROTO=`awk '{if ($1=="BOOTPROTO") {print $2}}' $NETCONFIG_FILE`
# set IP address, only usful to STATIC IP
STA_IPADDR=`awk '{if ($1=="IPADDR") {print $2}}' $NETCONFIG_FILE`
# set GATEWAY address, only usful to STATIC IP
STA_GATEWAY=`awk '{if ($1=="GATEWAY") {print $2}}' $NETCONFIG_FILE`
# set Wireless AP's SSID
STA_SSID=`awk '{if ($1=="SSID") { print $2 }}' $NETCONFIG_FILE`
if [ "$(echo "$STA_SSID" | cut -c1)" = '"' ]; then
	STA_SSID=`awk -F\" '{if ($1=="SSID ") { print $2 }}' $NETCONFIG_FILE`
fi


# set AUTH_MODE to OPEN/SHARED/WPAPSK/WPA2PSK
STA_AUTH_MODE=`awk '{if ($1=="AUTH_MODE") {print $2}}' $NETCONFIG_FILE`
# set ENCRYPT_TYPE to NONE/WEP/TKIP/AES
STA_ENCRYPT_TYPE=`awk '{if ($1=="ENCRYPT_TYPE") {print $2}}' $NETCONFIG_FILE`
# set authentication key to be either
# WEP-HEX example: 4142434445
# WEP-ASCII example: ABCDE
# TKIP/AES-ASCII: 8~63 ASCII
STA_AUTH_KEY=`awk '{if ($1=="AUTH_KEY") {print $2}}' $NETCONFIG_FILE`
# Trigger Key
STA_WPS_TRIG_KEY=`awk '{if ($1=="WPS_TRIG_KEY") {print $2}}' $NETCONFIG_FILE`

# set DEVICE to wlan0
AP_DEVICE=ap0
AP_CHIPSET=MT5931
AP_BOOTPROTO=STATIC
AP_CHANNEL=`awk '{if ($1=="AP_CHANNEL") {print $2}}' $NETCONFIG_FILE`
AP_IPADDR=`awk '{if ($1=="AP_IPADDR") {print $2}}' $NETCONFIG_FILE`
AP_SSID=`awk '{if ($1=="AP_SSID") { print $2}}' $NETCONFIG_FILE`
if [ "$(echo "$AP_SSID" | cut -c1)" = '"' ]; then
	AP_SSID=`awk -F\" '{if ($1=="AP_SSID ") { print $2 }}' $NETCONFIG_FILE`
fi

AP_AUTH_MODE=`awk '{if ($1=="AP_AUTH_MODE") {print $2}}' $NETCONFIG_FILE`
AP_ENCRYPT_TYPE=`awk '{if ($1=="AP_ENCRYPT_TYPE") {print $2}}' $NETCONFIG_FILE`
AP_AUTH_KEY=`awk '{if ($1=="AP_AUTH_KEY") {print "\042"$2"\042"}}' $NETCONFIG_FILE`

IsWPS=0

DeviceInit()
{
	CHIPSET=$1
	if [ ! -f ./$CHIPSET/init.sh ]; then
       		echo "cannot find file $PWD/$CHIPSET/init.sh" > $MSGTOTERMINAL
        	return 1
        fi

	./$CHIPSET/init.sh
	if [ $? != 0 ]; then
	        echo "Initialize $CHIPSET failure" > $MSGTOTERMINAL
	        return 2
	fi

        return 0
}

DeviceFini()
{
	CHIPSET=$1
	if [ ! -f ./$CHIPSET/fini.sh ]; then
       		echo "cannot find file $PWD/$CHIPSET/init.sh" > $MSGTOTERMINAL
        	return 1
        fi

	./$CHIPSET/fini.sh
	if [ $? != 0 ]; then
	        echo "Finalize $CHIPSET failure" > $MSGTOTERMINAL
	        return 2
	fi

        return 0
}


WaitingForConnected()
{
   sleep 1
   IsProcRun=`ps | grep "wpa_supplicant" | grep -v "grep" | sed -n '1P' | awk '{print $1}'`
   while [ 1 ]; do
         if [ $IsProcRun != "" ]; then break; fi
         IsProcRun=`ps | grep "wpa_supplicant" | grep -v "grep" | sed -n '1P' | awk '{print $1}'`
         sleep 1
   done

   counter=0

   while [ 1 ]; do

      WPSStatus=`./wpa_cli -p $CTRL_INTERFACE status | awk -F= '{if ($1=="wpa_state") {print $2}}'`

      echo "Wait.. ($counter/10) " > $MSGTOTERMINAL

      if [ "$WPSStatus" == "COMPLETED" ] && [ "$WPSStatus" != "" ]; then

		echo "Save configuration to file ..."
		./wpa_cli -p $CTRL_INTERFACE save_config

		echo "Show AP information"
		./wpa_cli -p $CTRL_INTERFACE status

		if [ $IsWPS = 1 ]; then
			echo "Restore to network_config"
			./wpa_conf_restore -f $WPA_CONF_FILE -o $NETCONFIG_FILE -t 0
		fi

		break;

      elif [ "$WPSStatus" == "INACTIVE" ]; 

		then return 5;

      fi

      counter=`expr $counter + 1`
      if [ $counter = 10 ]; then 
		echo "Timeout!!"
		return 6; 
      fi
      sleep 5

   done

   return 0
}


ConfigurationSta()
{   

   if DeviceInit $STA_CHIPSET; then 

	ifconfig $STA_DEVICE down
	ifconfig $STA_DEVICE up

        cat ./wpa.conf.default 			> $WPA_CONF_FILE
	
	echo "network={"			>>$WPA_CONF_FILE
	echo "	ssid=\"$STA_SSID\""		>>$WPA_CONF_FILE
	
	# set AUTH_MODE to OPEN/SHARED/WEPAUTO/WPAPSK/WPA2PSK/WPANONE
	case $STA_AUTH_MODE in
        "NONE")
		echo "		key_mgmt=NONE"          >>$WPA_CONF_FILE
        ;;
        "OPEN"|"SHARED")
		echo "	key_mgmt=NONE"		>>$WPA_CONF_FILE
		if [ "$STA_AUTH_MODE" == "SHARED" ]; then
                        echo "  auth_alg=SHARED"      >>$WPA_CONF_FILE
                else
	                echo "  auth_alg=OPEN"        >>$WPA_CONF_FILE
	        fi
                if [ "$STA_ENCRYPT_TYPE" != "NONE" ]; then
		        echo "  wep_key0=\"$STA_AUTH_KEY\""   >>$WPA_CONF_FILE
		        echo "  wep_tx_keyidx=0"        >>$WPA_CONF_FILE
		fi
	;;
        "WPAPSK"|"WPA2PSK")
		if [ "$STA_AUTH_MODE" == "WPAPSK" ]; then
	        	echo "	proto=WPA"	>>$WPA_CONF_FILE
		else
			echo "	proto=WPA2"	>>$WPA_CONF_FILE
		fi

                echo "	key_mgmt=WPA-PSK"       >>$WPA_CONF_FILE
	        case $STA_ENCRYPT_TYPE in
		"TKIP")	
	                echo "	pairwise=TKIP"  >>$WPA_CONF_FILE
		;;
                "AES")
                	echo "	pairwise=CCMP"  >>$WPA_CONF_FILE
                ;;			
		esac	
		echo "	psk=\"$STA_AUTH_KEY\""	>>$WPA_CONF_FILE	
        ;;

	*)
	        echo "The mode wasn't supported!!"
                return 0
	;;
        esac
	
	echo "}"	>>$WPA_CONF_FILE

	sync

  	killall wpa_supplicant
	rm -f $CTRL_INTERFACE"/"$STA_DEVICE


	./wpa_supplicant -c $WPA_CONF_FILE -i$STA_DEVICE -Dwext &
	sleep 1
 	counter=0
	while [ 1 ]; do
        	IsProcRun=`ps | grep "wpa_supplicant" | grep -v "grep" | sed -n '1P' | awk '{print $1}'`
	       	if [ "$IsProcRun" != "" ] || [ $counter = 10 ]; then break; fi
	       	counter=`expr $counter + 1`
		sleep 1	
	done

	if [ $counter != 10 ]; then 
	  	if WaitingForConnected; then return 0; fi
	fi
   fi
  
   killall wpa_supplicant

   ifconfig $STA_DEVICE down
   #DeviceFini $STA_CHIPSET

   return 1

}

ConfigurationSoftAP()
{
   if DeviceInit $AP_CHIPSET; then 

	ifconfig $AP_DEVICE down
	ifconfig $AP_DEVICE up

	AP_WPA=./p2p_supplicant
	AP_CLI=./p2p_cli

	killall p2p_supplicant
	rm -f $CTRL_INTERFACE"/"$AP_DEVICE

	echo "$AP_WPA -c $AP_CONF_FILE -i$AP_DEVICE -D nl80211 &"
	$AP_WPA -c $AP_CONF_FILE -i$AP_DEVICE -D nl80211 &
	counter=0
	while [ 1 ]; do

		IsProcRun=`ps | grep "p2p_supplicant" | grep -v "grep" | sed -n '1P' | awk '{print $1}'`

		echo "wait p2p_supplicant... ($counter/10)"

	        if [ "$IsProcRun" != "" ] || [ $counter = 10 ]; then break; fi

	        counter=`expr $counter + 1`

	        sleep 1	

	done

	if [ $counter != 10 ]; then

		MACADDR=`cat "/sys/class/net/"$AP_DEVICE"/address" | awk '{gsub(/:/,"-",$1); print $1}'`
		AP_SSID=`echo -e "\042$AP_SSID"_"$MACADDR\042"`
		echo $AP_SSID
 
		if [ "$STA_SSID" != "" ] && [ -S $CTRL_INTERFACE"/"$STA_DEVICE ]; then	 
			WPAStatus=`./wpa_cli -i $STA_DEVICE -p $CTRL_INTERFACE status | awk -F= '{if ($1=="wpa_state") {print $2}}'`
		fi

		if [ "$WPAStatus" == "COMPLETED" ]; then
			freq=`./wpa_cli -i $STA_DEVICE -p $CTRL_INTERFACE scan_result| awk '{if ($5=="'$STA_SSID'") {printf $2}}' `
			echo "freq=$freq"
			freq_off=`expr $freq - 2407`
			ch=`expr $freq_off / 5`
		else
			ch=$AP_CHANNEL
		fi

		echo "$ch"

		echo "$AP_cli -i $AP_DEVICE -p $CTRL_INTERFACE cfg_ap ssid $AP_SSID"
		counter=0
		while [ 1 ]; do
		        $AP_CLI -i $AP_DEVICE -p $CTRL_INTERFACE cfg_ap ssid "$AP_SSID"
	        	if [ $? = 0 ] || [ $counter = 10 ]; then break; fi
		        echo "Waiting for $AP_DEVICE ready" > $MSGTOTERMINAL
			sleep 1
		        counter=`expr $counter + 1`
		done

		if [ $counter != 10 ]; then

			if [ "$AP_AUTH_MODE" = "WPA2PSK" ] || [ "$AP_AUTH_MODE" = "WPAPSK" ]; then

				if [ "$AP_AUTH_MODE" = "WPA2PSK" ]; then
					$AP_CLI -i $AP_DEVICE -p $CTRL_INTERFACE cfg_ap sec '"wpa2-psk"'
				else
					$AP_CLI -i $AP_DEVICE -p $CTRL_INTERFACE cfg_ap sec '"wpa-psk"'
				fi
	
				$AP_CLI -i$AP_DEVICE -p $CTRL_INTERFACE cfg_ap key $AP_AUTH_KEY

			elif [ "$AP_AUTH_MODE" = "OPEN" ]; then

				$AP_CLI -i $AP_DEVICE -p $CTRL_INTERFACE cfg_ap sec '"open"'

			else

				echo "AP_AUTH_MODE \"$AP_AUTH_MODE\" does not support !!"

				return 1

			fi

			echo "AP_cli -i $AP_DEVICE -p $CTRL_INTERFACE cfg_ap ch $ch"
			if $AP_CLI -i $AP_DEVICE -p $CTRL_INTERFACE cfg_ap ch $ch; then
				echo "AP_cli -i $AP_DEVICE -p $CTRL_INTERFACE AP_enable_device"
				if $AP_CLI -i $AP_DEVICE -p $CTRL_INTERFACE p2p_enable_device; then
					echo "AP_cli -i $AP_DEVICE -p $CTRL_INTERFACE start_ap"
					if $AP_CLI -i $AP_DEVICE -p $CTRL_INTERFACE start_ap; then
						echo "AP_cli -i $AP_DEVICE -p $CTRL_INTERFACE status"
						if $AP_CLI -i $AP_DEVICE -p $CTRL_INTERFACE status; then return 0; fi 
					fi 
				fi 
			fi
		fi
	fi
  fi

  DeviceFini $AP_CHIPSET

  return 1

}

ConfigurationWPS()
{

if [ $# -ge 1 ]; then

   if DeviceInit $STA_CHIPSET; then 

	ifconfig $STA_DEVICE down
	ifconfig $STA_DEVICE up

        cat ./wpa.conf.default 				> $WPA_CONF_FILE
	
	CTRL_INTERFACE=`awk -F= '{if ($1=="ctrl_interface") {print $2}}' $WPA_CONF_FILE`

  	killall wpa_supplicant

	./wpa_supplicant -c $WPA_CONF_FILE -i$STA_DEVICE -Dwext &
	sleep 1
 	counter=0
	while [ 1 ]; do
        	IsProcRun=`ps | grep "wpa_supplicant" | grep -v "grep" | sed -n '1P' | awk '{print $1}'`
	       	if [ "$IsProcRun" != "" ] || [ $counter = 10 ]; then break; fi
	       	counter=`expr $counter + 1`
		sleep 1	
	done

	if [ $counter != 10 ]; then 

		if [ "$1" = "PBC" ]; then
			echo "start WPS PBC mode"	> $MSGTOTERMINAL
			./wpa_cli -p $CTRL_INTERFACE  -i $STA_DEVICE wps_pbc	> $MSGTOTERMINAL
		  	if WaitingForConnected; then return 0; fi

		elif [ "$1" = "PINE" ]; then
			echo "start WPS PIN Enrollee mode"	> $MSGTOTERMINAL
			PIN_CODE=`./wpa_cli -p $CTRL_INTERFACE  -i $STA_DEVICE wps_pin any`
			echo -e "\033[1;32mPlease enter the pin code into AP's wps_pin setup page\033[m" > $MSGTOTERMINAL
			echo -e "PIN CODE: \033[1;33m$PIN_CODE\033[m" > $MSGTOTERMINAL
		  	if WaitingForConnected; then return 0; fi
		fi

	fi

     killall wpa_supplicant

     ifconfig $STA_DEVICE down
     #DeviceFini $STA_CHIPSET

  fi

fi

return 1

}

DHCPSrv_Start()
{
	DHCPD_CONF_FILE=/tmp/dnsmasq.conf.$1
	DHCPD_RESOLV_FILE=/tmp/resolv-file.$1
	DHCPD_LEASES_FILE=/tmp/dnsmasq.leases.$1
	DHCPD_PID_FILE=/tmp/dnsmasq.pid.$1
	DHCPD_DEVICE=$AP_DEVICE
	DHCPD_IPADDR=$AP_IPADDR
			                
	echo "ifconfig $DHCPD_DEVICE $DHCPD_IPADDR netmask 255.255.255.0"
	if ifconfig $DHCPD_DEVICE $DHCPD_IPADDR netmask 255.255.255.0; then
		echo -e "My IP: \033[1;33m$DHCPD_IPADDR\033[1;33m" > $MSGTOTERMINAL
	fi

	echo "Starting DHCP server." > $MSGTOTERMINAL
	if [ -f $DHCPD_PID_FILE ]; then killall dnsmasq --pid-file=$DHCPD_PID_FILE ; fi
	if [ -f $DHCPD_CONF_FILE ] ; then rm -f $DHCPD_CONF_FILE; fi

             echo "interface=$DHCPD_DEVICE" > $DHCPD_CONF_FILE
             echo "resolv-file=$DHCPD_RESOLV_FILE" >> $DHCPD_CONF_FILE
             echo "dhcp-leasefile=$DHCPD_LEASES_FILE">> $DHCPD_CONF_FILE
             echo "dhcp-lease-max=10" >> $DHCPD_CONF_FILE
	     echo "dhcp-option=lan,3,$DHCPD_IPADDR" >> $DHCPD_CONF_FILE
	     # Append domain name
	     echo "domain=nuvoton.com" >> $DHCPD_CONF_FILE


             # Disable DNS-query server option.
             echo "dhcp-option=lan,6" >> $DHCPD_CONF_FILE

             # DHCP release on Window platform.
             echo "dhcp-option=vendor:MSFT,2,1i" >> $DHCPD_CONF_FILE

             echo "dhcp-authoritative">> $DHCPD_CONF_FILE
             SUBNET=`echo $DHCPD_IPADDR | awk '{FS="."} {print $1 "." $2 "." $3}'`
             echo "dhcp-range=lan,$SUBNET.100,$SUBNET.109,255.255.255.0,14400m" >> $DHCPD_CONF_FILE
             echo "stop-dns-rebind" >> $DHCPD_CONF_FILE
             sync

	./dnsmasq --pid-file=$DHCPD_PID_FILE --conf-file=$DHCPD_CONF_FILE  --user=root --group=root --dhcp-fqdn &
}

ConfigurationIPAddr()
{
	if [ "$STA_BOOTPROTO" == "DHCP" ] || [  $IsWPS = 1 ] ; then
  		if [ ! -d /usr/netplug ]; then
			killall udhcpc
   			echo -e "Leasing an IP address ..." > $MSGTOTERMINAL
		    	echo "udhcpc -i $STA_DEVICE"
    			udhcpc -i $STA_DEVICE -q -T 2
    			echo -e "Got IP: \033[1;33m"`ifconfig $STA_DEVICE | grep inet | awk '{FS=":"} {print $2}' | sed 's/[^0-9\.]//g'`"\033[m" > $MSGTOTERMINAL
		else
    			echo "auto  $STA_DEVICE" >> /etc/network/interfaces                   
			echo "	iface $STA_DEVICE inet dhcp" >> /etc/network/interfaces    
			if ! cat /etc/netplug/netplugd.conf | grep $STA_DEVICE; then
				echo $STA_DEVICE >> /etc/netplug/netplugd.conf
			fi
		fi
	elif [ "$STA_BOOTPROTO" == "STATIC" ]; then
		if [ ! -d /usr/netplug ]; then
			echo "ifconfig $STA_DEVICE $STA_IPADDR netmask 255.255.255.0"
			if ifconfig $STA_DEVICE $STA_IPADDR netmask 255.255.255.0; then
				echo -e "My IP: \033[1;33m$STA_IPADDR\033[1;33m" > $MSGTOTERMINAL
				if route add default gw $STA_GATEWAY; then
					echo -e "Gateway: \033[1;33m$STA_GATEWAY\033[1;33m" > $MSGTOTERMINAL
					echo "nameserver 168.95.1.1" > /etc/resolv.conf
				fi
			fi
		else
			echo "auto  $STA_DEVICE" >> /etc/network/interfaces
		  	echo "	iface $STA_DEVICE inet static" >> /etc/network/interfaces
			echo "	address $STA_IPADDR" >> /etc/network/interfaces
		  	echo "	netmask 255.255.255.0" >> /etc/network/interfaces
			if ! cat /etc/netplug/netplugd.conf | grep $STA_DEVICE; then
 				echo $STA_DEVICE >> /etc/netplug/netplugd.conf
 			fi
		fi
	fi
}

# Mode
case $1 in
   "WPS")
	IsWPS=1
	case $2 in
	"PBC"|"PINE")
		IsWPS=1
		if ConfigurationWPS $2; then 
			ConfigurationIPAddr $STA_DEVICE
		fi
               ./network.sh SoftAP
                exit $?
	;;
	*)
                echo "[WPS] No support $2 in $1 mode" > $MSGTOTERMINAL
		echo "Usage: ./network.sh WPS PBC|PINE" > $MSGTOTERMINAL
                exit 1
	;;
        esac
   ;;
   "SoftAP")
	if ConfigurationSoftAP; then 
		DHCPSrv_Start $AP_DEVICE
	else
		exit 1
	fi
   ;;
   "Infra"|*)
        if  [ "$STA_SSID" != "" ]; then
                if ConfigurationSta; then
                        ConfigurationIPAddr $STA_DEVICE
                fi
        fi
        ./network.sh SoftAP
        exit $?
    ;;
esac

TS=`cat /proc/uptime | awk '{print $1}'`
echo -e "\033[1;33m[$TS] network-$1 done.\033[m"

exit 0

Please copy whole "wifi" folder to /mnt/nand1-1/, 
and follow below steps to create a WiFi connection.

  1. type "cd /mnt/nand1-1/wifi" to change path to wifi directory
  2. edit network_config to set network configuration at first time.
     Please refer below descriptions to know what options you can choice.
  3. type "./wifi.sh" to startup a WiFi connection

[Example of network_config for STA Infra mode]
# set STA_ENABLE to YES/NO
# set STA_CHIPSET to MT5931
# set STA_BOOTPROTO to DHCP/STATIC
# set STA_IPADDR is only usful to STATIC IP
# set STA_GATEWAY is only usful to STATIC IP, a space means does not set it
# set STA_NETWORK_TYPE to Infra/Adhoc, only Infra is supported now
# set STA_SSID to Wireless AP's SSID
# set STA_AUTH_MODE to OPEN/SHARED/WPAPSK/WPA2PSK/WPSPBC/WPSPIN/WPSREG
#	when WPSREG is selected, user need to fill STA_SSID and STA_AUTH_KEY fields,
#	and STA_AUTH_KEY field means the PIN code of STA_SSID
# set STA_ENCRYPT_TYPE to NONE/WEP/TKIP/AES
# set STA_AUTH_KEY to authentication key, it could be
# 	WEP-HEX example: 4142434445
# 	WEP-ASCII example: "ABCDE"
# 	TKIP/AES-ASCII: 8~63 ASCII

STA_ENABLE YES
STA_CHIPSET MT5931
STA_BOOTPROTO DHCP
STA_IPADDR 192.168.11.99 
STA_GATEWAY 192.168.11.1
STA_NETWORK_TYPE Infra
STA_SSID BUFFALO-G300N
STA_AUTH_MODE WPA2PSK
STA_ENCRYPT_TYPE AES
STA_AUTH_KEY 1234567890

[Example of network_config for AP mode]
# set AP_ENABLE to YES/NO
# set AP_CHIPSET to MT5931
# set AP_IPADDR to IP address
# set AP_GATEWAY to gateway IP, a space means does not set it
# set AP_SSID to Wireless AP's SSID
# set AP_AUTH_MODE to OPEN/WPAPSK/WPA2PSK
# set AP_AUTH_KEY to authentication key, it could be
# 	TKIP/AES-ASCII: 8~63 ASCII
# set AP_CHANNEL to the channel number of AP, is only usful to STA_ENABLE is NO
#	If station mode is enabled, this channel number must be the same to station's AP

AP_ENABLE YES
AP_CHIPSET MT5931
AP_IPADDR 192.168.2.1 
AP_GATEWAY 192.168.2.1
AP_SSID Nuvoton_AP
AP_AUTH_MODE WPA2PSK
AP_AUTH_KEY 1234567890
AP_CHANNEL 8

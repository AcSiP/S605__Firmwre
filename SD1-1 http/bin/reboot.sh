#!/bin/sh

sync
sleep 1

if grep 2.6.17.14 /proc/version; then
	clk_path=`ls /sys/devices/platform/*-clk/clock`
	echo "pr" > $clk_path
else
	reboot
fi

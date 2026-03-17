#!/usr/bin/env bash

# bluetooth: off        = state: Warning
# bluetooth: on         = state: Idle
# bluetooth: connected  = state: Good

BLU_CNT_CONTROLLER=$(find /sys/class/bluetooth/* | wc -l)

if [[ $BLU_CNT_CONTROLLER -gt 0 ]]
then
	BLU_POWER=$(bluetoothctl show | grep -q 'Powered: yes$'; echo "$?")
	if [[ $BLU_POWER -eq 0 ]]
	then
		BLU_DEVICES="$( bluetoothctl devices Connected )"
		BLU_CONNECTED="$( echo "${BLU_DEVICES}" | cut -d ' ' -f3- )"
		BLU_CONNECTED_MAC="$( echo "${BLU_DEVICES}" | cut -d ' ' -f2 )"
		DEV_BATTERY=$( echo "info $BLU_CONNECTED_MAC" | bluetoothctl | sed -n '/Battery Percentage:/ s/.*(\([0-9]*\).*/\1/p' )
		if [[ $BLU_CONNECTED != "" ]]
		then
			echo "{\"icon\": \"\", \"state\": \"Good\", \"text\": \" $BLU_CONNECTED $DEV_BATTERY%\", \"short_text\": \" $BLU_CONNECTED $DEV_BATTERY%\"}"
		else
			echo "{\"icon\": \"\", \"state\": \"Idle\", \"text\": \"\", \"short_text\": \"\"}"
		fi
	else
		echo "{\"icon\": \"\", \"state\": \"Warning\", \"text\": \"󰂲\", \"short_text\": \"󰂲\"}"
	fi
else
	echo "{\"icon\": \"\", \"state\": \"Warning\", \"text\": \"󰂲\", \"short_text\": \"󰂲\"}"
fi

# This might be better down below:

##!/usr/bin/env bash
#
## 1. Instantly check if Bluetooth is powered on by reading the kernel directly.
## This avoids spawning 'bluetoothctl', 'find', or 'grep' entirely.
#POWER="off"
#for dir in /sys/class/rfkill/rfkill*/; do
#    if [[ -f "${dir}type" ]] && { read -r type < "${dir}type"; [[ "$type" == "bluetooth" ]]; }; then
#        read -r state < "${dir}state"
#        if [[ "$state" == "1" ]]; then
#            POWER="on"
#        fi
#        break
#    fi
#done
#
## If it's powered off or doesn't exist, exit immediately.
#if [[ "$POWER" == "off" ]]; then
#    echo '{"icon": "", "state": "Warning", "text": "󰂲", "short_text": "󰂲"}'
#    exit 0
#fi
#
## 2. Controller is ON. Check for connected devices in ONE call.
#CONN_INFO=$(bluetoothctl devices Connected)
#
#if [[ -z "$CONN_INFO" ]]; then
#    # Powered on, but nothing connected
#    echo '{"icon": "", "state": "Idle", "text": "", "short_text": ""}'
#    exit 0
#fi
#
## 3. A device is connected. Extract MAC and Name using Bash built-ins (no 'cut').
## (If multiple are connected, this grabs the first one).
#read -r _ MAC NAME <<< "$CONN_INFO"
#
## 4. ONE call to get battery percentage (using awk instead of a heavy sed pipe).
#BAT_INFO=$(bluetoothctl info "$MAC" | awk -F'[()]' '/Battery Percentage/ {print $2}')
#
#if [[ -n "$BAT_INFO" ]]; then
#    echo "{\"icon\": \"\", \"state\": \"Good\", \"text\": \" $NAME $BAT_INFO%\", \"short_text\": \" $NAME $BAT_INFO%\"}"
#else
#    echo "{\"icon\": \"\", \"state\": \"Good\", \"text\": \" $NAME\", \"short_text\": \" $NAME\"}"
#fi

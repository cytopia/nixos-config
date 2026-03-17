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
		BLU_CONNECTED=$(bluetoothctl devices Connected | cut -d ' ' -f3-)
		BLU_CONNECTED_MAC=$(bluetoothctl devices Connected | cut -d ' ' -f2)
		DEV_BATTERY=$(echo "info $BLU_CONNECTED_MAC" | bluetoothctl | sed -n '/Battery Percentage:/ s/.*(\([0-9]*\).*/\1/p')
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

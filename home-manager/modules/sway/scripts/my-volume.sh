#!/bin/sh -eu


################################################################################
#
# VARIABLES
#
################################################################################

ACTION=
INTERVAL="5"
SINK="@DEFAULT_AUDIO_SINK@"



################################################################################
#
# FUNCTIONS
#
################################################################################

print_usage_head() {
	printf "Usage: %s [OPTIONS] -c COMMAND\n" "${0}"
	printf "       %s -h\n"  "${0}"
}
print_usage() {
	print_usage_head

	printf "\nThis script is a wrapper for wpctl that will change the volume\n"
	printf "and send those changes to a notification daemine.\n\n"

	printf "COMMAND:\n"
	printf "  -c up           Increase volume.\n"
	printf "  -c down         Decrease volume.\n"
	printf "  -c mute         Mute volume.\n"
	printf "  -c toggle       Toggle mute/unmute.\n\n"

	printf "OPTIONS:\n"
	printf "   -i <interval>  Change the interval for volume up/down.\n"
	printf "                  The default is 5 (percent).\n\n"

	printf "   -S <sink>      Specify AUDIO_SINK.\n"
	printf "                  If omitted using '@DEFAULT_AUDIO_SINK@'.\n\n"

	printf "HELP:\n"
	printf "   -h             Show help.\n"
}



################################################################################
#
# COMMAND LINE ARGUMENTS
#
################################################################################

############################################################
# Parse arguments
############################################################
while [ "${#}" -gt 0  ]; do
	case "${1}" in
		-c)
			shift
			if [ "${1}" != "up" ] && [ "${1}" != "down" ] && [ "${1}" != "mute" ] && [ "${1}" != "toggle" ]; then
				printf "Error, -c must either be 'up', 'down', 'mute' or 'toggle'.\n"
				print_usage_head
				exit 1
			fi
			ACTION="${1}"
			;;
		-i)
			shift
			if ! printf "%d" "${1}" >/dev/null 2>&1; then
				printf "Error, the value for -i must be an integer.\n"
				print_usage_head
				exit 1
			fi
			INTERVAL="${1}"
			;;
		-S)
			shift
			SINK="${1}"
			;;
		-h)
			print_usage
			exit
			;;
		*)
			printf "Unknown argument: %s\n" "${1}"
			print_usage_head
			exit 1
			;;
	esac
	shift
done

############################################################
# Check required arguments
############################################################
if [ "${ACTION}" = "" ]; then
	printf "Error, -c is mandatory.\n"
	print_usage_head
	exit 1
fi



################################################################################
#
# MAIN ENTRYPOINT
#
################################################################################

############################################################
# Rum command
############################################################


MUTE=""
VOLUME=""

if [ "${ACTION}" = "up" ]; then
	wpctl set-mute "${SINK}" 0
	wpctl set-volume "${SINK}" "${INTERVAL}%+"
	STATUS="$( wpctl get-volume "${SINK}" )"
	VOLUME="$( echo "${STATUS}" | awk '{print int($2 * 100)}' )"

elif [ "${ACTION}" = "down" ]; then
	wpctl set-mute "${SINK}" 0
	wpctl set-volume "${SINK}" "${INTERVAL}%-"
	STATUS="$( wpctl get-volume "${SINK}" )"
	VOLUME="$( echo "${STATUS}" | awk '{print int($2 * 100)}' )"

elif [ "${ACTION}" = "mute" ]; then
	wpctl set-mute "${SINK}" 1
	MUTE="muted"

elif [ "${ACTION}" = "toggle" ]; then
	wpctl set-mute "${SINK}" toggle
	STATUS="$( wpctl get-volume "${SINK}" )"
	if echo "${STATUS}" | grep -q '[MUTED]'; then
		MUTE="muted"
	else
		MUTE="unmuted"
		VOLUME="$( echo "${STATUS}" | awk '{print int($2 * 100)}' )"
	fi
fi

if [ "${MUTE}" = "muted" ]; then
	notify-send "Volume" "Muted" \
		-i audio-volume-muted \
		-h string:x-canonical-private-synchronous:volume \
		-h int:value:0 \
		-u low \
		-a "System"

elif [ "${MUTE}" = "unmuted" ]; then
	notify-send "Volume" "Unmuted ${VOLUME}%" \
		-i audio-volume-high \
		-h string:x-canonical-private-synchronous:volume \
		-h "int:value:${VOLUME}" \
		-u low \
		-a "System"

else
	if [ "${ACTION}" = "up" ]; then
		notify-send "Volume" "${VOLUME}%" \
			-i audio-volume-high \
			-h string:x-canonical-private-synchronous:volume \
			-h "int:value:${VOLUME}" \
			-u low \
			-a "System"
	elif [ "${ACTION}" = "down" ]; then
		notify-send "Volume" "${VOLUME}%" \
			-i audio-volume-low \
			-h string:x-canonical-private-synchronous:volume \
			-h "int:value:${VOLUME}" \
			-u low \
			-a "System"
	fi
fi

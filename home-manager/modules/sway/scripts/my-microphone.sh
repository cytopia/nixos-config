#!/bin/sh -eu


################################################################################
#
# VARIABLES
#
################################################################################

ACTION=
SINK="@DEFAULT_AUDIO_SOURCE@"



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

	printf "\nThis script is a wrapper for wpctl that will change the microphone volume\n"
	printf "and send those changes to a notification daemine.\n\n"

	printf "COMMAND:\n"
	printf "  -c mute         Mute microphone.\n"
	printf "  -c toggle       Toggle mute/unmute.\n\n"

	printf "   -S <sink>      Specify AUDIO_SOURCE.\n"
	printf "                  If omitted using '@DEFAULT_AUDIO_SOURCE@'.\n\n"

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
			if [ "${1}" != "mute" ] && [ "${1}" != "toggle" ]; then
				printf "Error, -c must be either 'mute' or 'toggle'.\n"
				print_usage_head
				exit 1
			fi
			ACTION="${1}"
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

if  [ "${ACTION}" = "mute" ]; then
	wpctl set-mute "${SINK}" 1
	MUTE="muted"

elif  [ "${ACTION}" = "toggle" ]; then
	wpctl set-mute "${SINK}" toggle
	STATUS="$( wpctl get-volume "${SINK}" )"
	if echo "${STATUS}" | grep -q '[MUTED]'; then
		MUTE="muted"
	else
		MUTE="unmuted"
	fi
fi

if [ "${MUTE}" = "muted" ]; then
	notify-send "Microphone" "Muted" \
		-i microphone-sensitivity-muted-symbolic \
		-h string:x-canonical-private-synchronous:mic \
		-h int:value:0 \
		-u low \
		-a "System"

elif [ "${MUTE}" = "unmuted" ]; then
	notify-send "Microphone" "Unmuted" \
		-i microphone-sensitivity-high-symbolic \
		-h string:x-canonical-private-synchronous:mic \
		-h int:value:100 \
		-u low \
		-a "System"
fi

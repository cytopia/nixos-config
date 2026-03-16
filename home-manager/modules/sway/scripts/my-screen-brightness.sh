#!/bin/sh -eu


################################################################################
#
# VARIABLES
#
################################################################################

ACTION=
INTERVAL="5"



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

	printf "\nThis script is a wrapper for brightnessctl that will change the brightness\n"
	printf "of the screen and send those changes to a notification daemon.\n\n"

	printf "COMMAND:\n"
	printf "  -c up           Increase brghtness.\n"
	printf "  -c down         Decrease brightness.\n"

	printf "OPTIONS:\n"
	printf "   -i <interval>  Change the interval for brightness up/down.\n"
	printf "                  The default is 5 (percent).\n\n"

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
			if [ "${1}" != "up" ] && [ "${1}" != "down" ]; then
				printf "Error, -c must either be 'up' or 'down'.\n"
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

PERCENT=""
if [ "${ACTION}" = "up" ]; then
	brightnessctl set "${INTERVAL}%+"
	PERCENT="$( (brightnessctl get && brightnessctl max) | awk 'NR==1{val=$1} NR==2{printf "%.0f\n", (val/$1)*100}')"

elif [ "${ACTION}" = "down" ]; then
	brightnessctl set "${INTERVAL}%-"
	PERCENT="$( (brightnessctl get && brightnessctl max) | awk 'NR==1{val=$1} NR==2{printf "%.0f\n", (val/$1)*100}')"
fi

notify-send -a "System" \
    -h int:value:"${PERCENT}" \
    -h string:x-canonical-private-synchronous:brightness \
    -i display-brightness "Screen" "${PERCENT}%"

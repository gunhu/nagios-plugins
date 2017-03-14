#!/bin/sh
#
# Check PF counter "current entries" with hard limit
#
# Last Modified: 13-03-2017
#
# Usage: ./check_pfctl -w <value> -c <value>
#
# Description:
#
# Example: check_pfctl.sh -w 80 -c 90                                      
#
# Output: PF OK - states: 3743 (37% - limit: 10000)|states=3743;8000;9000;0;10000
#

# Paths to commands used in this script
# (You may have to modify this based on your system configuration)

PROGNAME=$(basename "$0")
PROGPATH=$(echo "$0" | sed -e 's,[\\/][^\\/][^\\/]*$,,')
REVISION="@NP_VERSION@"
VERSION="Version 1.0,"
AUTHOR="2017, Alexis VACHETTE"

. "$PROGPATH"/utils.sh

# Commands

pfctl="/sbin/pfctl"

# List of arrays
set -A counters "current entries"
set -A offset 3
set -A limits;
set -A results;
i="0";

# Functions

print_version() {
    echo "$VERSION $AUTHOR"
}

print_help() {
    print_version $PROGNAME $VERSION
    echo ""
    echo "./$PROGNAME -w <value> -c <value>"
    echo ""
    echo "Options:"
    echo "  -w|--warning)"
    echo "    Warning thresholds"
    echo "  -c|--critical)"
    echo "    Critical thresholds"
}

pfctl_counters() {
    local output=$($pfctl -si 2>&1)
    while [[ $i -ne ${#counters[@]} ]]
    do
    local temp=$(echo "$output" | awk '
        BEGIN { counter=0; }
        /'"${counters[$i]}"'/ { counter = $'"${offset[$i]}"' }
        END { print counter }
        ')
    results[${#results[*]}]=$temp
    i=$(($i + 1))
    done
}

pfctl_limit() {
    local output=$($pfctl -sm 2>&1)
    local limit=$(echo "$output" | awk '
        BEGIN { limit=0 }
        /states/ { limit = $4 }
        END { print limit }
        ')
    limits[${#limits[*]}]=$limit
}

pfctl_print() {
    local warning=$((${limits[0]}*$MAX_WARNING/100))
    local critical=$((${limits[0]}*$MAX_CRITICAL/100))
    local used=$((${results[0]}/100))

    if [ $used -lt $warning ]; then
        echo "PF OK - states: ${results[0]} ($used% - limit: ${limits[0]})|states=${results[0]};$warning;$critical;0;${limits[0]}"
        exit "$STATE_OK"
    elif [ $used -lt $critical ]; then
        echo "PF WARNING - states: ${results[0]} ($used% - limit: ${limits[0]})|states=${results[0]};$warning;$critical;0;${limits[0]}"
        exit "$STATE_WARNING"
    elif [ $used -ge $critical ]; then
        echo "PF CRITICAL - states: ${results[0]} ($used% - limit: ${limits[0]})|states=${results[0]};$warning;$critical;0;${limits[0]}"
        exit "$STATE_CRITICAL"
    fi
}

pfctl_stats() {
        pfctl_counters ${counters} ${offset}
        pfctl_limit
        pfctl_print ${results} ${limits}
}

# Make sure the correct number of command line
# arguments have been supplied

if [ $# -lt 1 ]; then
    print_help
    exit "$STATE_UNKNOWN"
fi

# Grab command line arguments
while test -n "$1"; do
    case "$1" in
        --help)
            print_help
            exit "$STATE_OK"
            ;;
        -h)
            print_help
            exit "$STATE_OK"
            ;;
        --version)
            print_revision "$PROGNAME" $REVISION
            exit "$STATE_OK"
            ;;
        -V)
            print_revision "$PROGNAME" $REVISION
            exit "$STATE_OK"
            ;;
        -c)
            MAX_CRITICAL=$2
            shift
            ;;
        --critical)
            MAX_CRITICAL=$2
            shift
            ;;
        -w)
            MAX_WARNING=$2
            shift
            ;;
        --warning)
            MAX_WARNING=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo ""
            print_help
            exit "$STATE_UNKNOWN"
            ;;
    esac
    shift
done

pfctl_stats

exit "$exitstatus"

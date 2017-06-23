#!/bin/ksh

###################################################
# Nagios plugin to check RAID status on OpenBSD   #
# Author: Alexis VACHETTE (avachette@sisteer.com) #
###################################################

VERSION="Version 1.0"
AUTHOR="(c) 2015 Alexis VACHETTE (avachette@sisteer.com)"

RAID_STATUS=`/usr/sbin/sysctl -a | grep hw.sensors.$1 | cut -f2 -d"=" | cut -f1 -d","`

# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Main #########################################################################

if [[ "$RAID_STATUS" == *"failed"* ]]; then
   echo "CRITICAL - RAID $RAID_STATUS"
   exit $STATE_CRITICAL
elif [[ "$RAID_STATUS" == *"degraded"* ]]; then
   echo "CRITICAL - RAID $RAID_STATUS"
   exit $STATE_CRITICAL
elif [[ "$RAID_STATUS" == *"rebuilding"* ]]; then
   echo "WARNING - RAID $RAID_STATUS"
   exit $STATE_WARNING
else
   echo "OK - RAID $RAID_STATUS"
   exit $STATE_OK
fi

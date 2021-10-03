#!/bin/sh

# wait until we are connected
#until ping -c 1 'ping.sunet.se' >/dev/null 2>&1; do
#	sleep 10
#done

COUNT=$(apt list --upgradable 2>/dev/null | grep "upgradable" -c)
echo "PKG: $COUNT"

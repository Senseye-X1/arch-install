#!/bin/sh

# wait until we are connected
#until ping -c 1 'ping.sunet.se' >/dev/null 2>&1; do
#	sleep 10
#done

while true; do
	COUNT=$(apt list --upgradable 2>/dev/null | grep "upgradable" -c)
	if [ "$COUNT" -gt 0 ]; then
		echo "PKG: $COUNT"
		# recheck when the log is written to or after 1 hour
		inotifywait -q -q -t 3600 -e close_write /var/log/apt/history.log
		sleep 5
	else
		echo "PKG: $COUNT"
		sleep 3600 # only do a recheck every hour to save some cpu time
	fi
done

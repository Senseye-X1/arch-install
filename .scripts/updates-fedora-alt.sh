#!/bin/sh

# wait until were connected
#until ping -c 1 'ping.sunet.se' >/dev/null 2>&1; do
#	sleep 10
#done

while true; do
	COUNT=$(dnf check-update 2>/dev/null | grep -c "\supdates")
	if [ "$COUNT" -gt 0 ]; then
		echo "PKG: $COUNT"
		# recheck when the log is written to or after 1 hour
		inotifywait -q -q -t 3600 -e close_write /var/log/dnf.rpm.log
		sleep 5
	else
		echo "PKG: $COUNT"
		sleep 3600 # only do a recheck every hour to save some cpu time
	fi
done

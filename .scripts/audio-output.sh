#!/bin/bash

#sinkindex=$(pacmd list-sinks | grep "* index:" | tail -c 2)
if (( $(pacmd list-sinks | grep "* index:" | awk '{print int($3)}') == 0))
	then
		pacmd set-default-sink 2
#		echo ""
	else
		pacmd set-default-sink 0
#		echo ""
fi
	

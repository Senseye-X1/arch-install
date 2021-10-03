#!/bin/bash

if (($(pacmd list-sinks | grep "* index:" | awk '{print int($3)}') == 0))
	then
		echo ""
	else
		echo ""
fi
	

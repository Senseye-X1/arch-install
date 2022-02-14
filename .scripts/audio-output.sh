#!/bin/bash

#sinkindex=$(pacmd list-sinks | grep "* index:" | tail -c 2)
#if (( $(pacmd list-sinks | grep "* index:" | awk '{print int($3)}') == 0))
	#then
		#pacmd set-default-sink 3
##		echo ""
	#else
		#pacmd set-default-sink 0
##		echo ""
#fi

if [[ "$(pactl get-default-sink)"  = "alsa_output.usb-Corsair_Simple_Audio_Listen_00000001-00.analog-stereo" ]]
	then
		pactl set-default-sink alsa_output.usb-SteelSeries_Arctis_Pro_Wireless-00.analog-stereo
#		echo ""
	else
		pacmd set-default-sink alsa_output.usb-Corsair_Simple_Audio_Listen_00000001-00.analog-stereo
#		echo ""
fi

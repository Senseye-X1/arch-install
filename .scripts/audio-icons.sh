#!/bin/bash

#if (($(pacmd list-sinks | grep "* index:" | awk '{print int($3)}') == 0))
	#then
		#echo ""
	#else
		#echo ""
#fi
	
if [[ "$(pactl get-default-sink)"  = "alsa_output.usb-Corsair_Simple_Audio_Listen_00000001-00.analog-stereo" ]]
	then
#		pactl set-default-sink alsa_output.usb-SteelSeries_Arctis_Pro_Wireless-00.analog-stereo
		echo ""
	else
#		pacmd set-default-sink alsa_output.usb-Corsair_Simple_Audio_Listen_00000001-00.analog-stereo
		echo ""
fi

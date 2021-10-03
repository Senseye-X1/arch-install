#!/bin/bash

PDIR="$HOME/.scripts"
LAUNCH="polybar-msg cmd restart"
ROFIDIR="$HOME/.config/rofi/themes"
AC="#000000"

fromhex () {
	hex="${1//#}"
	r=$(printf '0x%0.2s' "$hex")
	g=$(printf '0x%0.2s' "${hex#??}")
	b=$(printf '0x%0.2s' "${hex#????}")
	echo "$(( (r<75?0:(r-35)/40)*6*6 + 
		(g<75?0:(g-35)/40)*6   +
		(b<75?0:(b-35)/40)     + 16 ))"
}

color_change () {
	AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
	HEX=$(fromhex "$AC")
	sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
	sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
	sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
	sed -i -e 's/;[0-9]*;1m/;'"$HEX"';1m/g' ~/.bashrc
	$LAUNCH &
	killall dunst
}

color_change "$1"

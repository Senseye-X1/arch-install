#!/bin/bash

PDIR="$HOME/.scripts"
LAUNCH="polybar-msg cmd restart"
ROFIDIR="$HOME/.config/rofi/themes"
AC="#000000"

#color_change () {
#AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
#echo "$AC"
#HEX=$(~/.scripts/fromhex "$AC")
#echo "$HEX"
##sed -i -e 's/;[0-9]*;1m/;'"$HEX"';1m/g' ~/.bashrc
#}

#color_change "$1"

if  [[ $1 = "-default" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-amber" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
#HEX=$(~/.scripts/fromhex "$AC")
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
#sed -i -e 's/;[0-9]*;1m/;'"$AC"';1m/g' ~/.bashrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-blue" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-bluegrey" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-brown" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-cyan" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-darkorange" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-darkpurple" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-green" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-grey" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-indigo" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-lightblue" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-lightgreen" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-lime" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-orange" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-pink" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-purple" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-red" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-teal" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

elif  [[ $1 = "-yellow" ]]; then
# Replacing colors
AC=$(grep -m1 "${1//-}"' = #' ~/.scripts/colors.ini | awk '{print $3}')
sed -i -e 's/ac = .*/ac = '"$AC"'/g' $PDIR/colors.ini
sed -i -e 's/ac:.*/ac: '"$AC"'\;/g' $ROFIDIR/color-switch.rasi
sed -i -e 's/frame_color = ".*/frame_color = "'"$AC"'"/g' ~/.config/dunst/dunstrc
# Restarting polybar
$LAUNCH &
killall dunst

else
echo "Available options:
-amber		-blue			-bluegrey		-brown
-cyan		-darkorange		-darkpurple		-green
-grey		-indigo			-lightblue		-lightgreen
-lime		-orange			-pink			-purple
-red		-teal			-yellow			-default"
fi

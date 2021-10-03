#!/bin/bash

SDIR="$HOME/.scripts"

MENU="$(rofi -sep "|" -dmenu -i -p 'Color' -location 3 -columns 1 -xoffset -10 -yoffset 50 -width 12 -hide-scrollbar -line-padding 4 -padding 20 -lines 10 <<< "Amber|Blue|Blue Grey|Brown|Cyan|Dark Orange|Dark Purple|Green|Grey|Indigo|Light Blue|Light Green|Lime|Orange|Pink|Purple|Red|Teal|Yellow")"
            case "$MENU" in
				*Default) $SDIR/color_change.sh -default ;;
				*Amber) $SDIR/color_change.sh -amber ;;
				*Blue) $SDIR/color_change.sh -blue ;;
				*Blue*Grey) $SDIR/color_change.sh -bluegrey ;;
				*Brown) $SDIR/color_change.sh -brown ;;
				*Cyan) $SDIR/color_change.sh -cyan ;;
				*Dark*Orange) $SDIR/color_change.sh -darkorange ;;
				*Dark*Purple) $SDIR/color_change.sh -darkpurple ;;
				*Green) $SDIR/color_change.sh -green ;;
				*Grey) $SDIR/color_change.sh -grey ;;
				*Indigo) $SDIR/color_change.sh -indigo ;;
				*Light*Blue) $SDIR/color_change.sh -lightblue ;;
				*Light*Green) $SDIR/color_change.sh -lightgreen ;;
				*Lime) $SDIR/color_change.sh -lime ;;
				*Orange) $SDIR/color_change.sh -orange ;;
				*Pink) $SDIR/color_change.sh -pink ;;
				*Purple) $SDIR/color_change.sh -purple ;;
				*Red) $SDIR/color_change.sh -red ;;
				*Teal) $SDIR/color_change.sh -teal ;;
				*Yellow) $SDIR/color_change.sh -yellow
            esac

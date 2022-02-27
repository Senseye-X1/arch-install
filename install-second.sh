#!/bin/bash

timedatectl set-ntp true
localectl set-x11-keymap se

sudo systemctl enable lightdm

git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si --noconfirm
cd

paru polybar

echo "All done!

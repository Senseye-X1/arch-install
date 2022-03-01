#!/usr/bin/env -S bash -e

timedatectl set-ntp true
localectl set-x11-keymap se

cd
git clone https://github.com/Senseye-X1/dotfiles.git
chmod +x /home/$username/dotfiles/bspwm/\.config/bspwm/bspwmrc
chmod +x /home/$username/dotfiles/polybar/\.config/polybar/launch.sh
chmod -R +x /home/$username/dotfiles/scripts/\.scripts

cd
mkdir builds
cd builds
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si --noconfirm
cd

paru polybar

sudo systemctl enable lightdm

echo -e "All done!\nReboot and login."

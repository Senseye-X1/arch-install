#!/bin/bash

#sudo timedatectl set-ntp true
#sudo hwclock --systohc
#sudo umount /.snapshots
#sudo rm -r /.snapshots
#sudo snapper -c root create-config /
#sudo btrfs subvolume delete /.snapshots
#sudo mkdir /.snapshots
#sudo mount -a
#sudo chmod 750 /.snapshots
#sudo chmod a+rx /.snapshots
#sudo chown :andreas /.snapshots
#sudo sed -i 's/ALLOW_USERS=""/ALLOW_USERS="andreas"/' /etc/snapper/configs/root
#sudo sed -i 's/TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' /etc/snapper/configs/root
#sudo sed -i 's/TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' /etc/snapper/configs/root
#sudo sed -i 's/TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="0"/' /etc/snapper/configs/root
#sudo sed -i 's/TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/' /etc/snapper/configs/root
#sudo sed -i 's/TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root

#sudo firewall-cmd --add-port=1025-65535/tcp --permanent
#sudo firewall-cmd --add-port=1025-65535/udp --permanent
#sudo firewall-cmd --reload

print "Main packages."

sudo pacman -S accountsservice archlinux-wallpaper bspwm dunst feh firefox geany gnome-themes-extra kitty light-locker lightdm-gtk-greeter lightdm-gtk-greeter-settings lxappearance-gtk3 numlockx picom rofi sxhkd xautolock xorg zsh zsh-autosuggestions zsh-completions

git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si --noconfirm
cd

paru polybar

sudo systemctl enable lightdm
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
sudo systemctl enable grub-btrfs.path

sudo mkdir /etc/pacman.d/hooks
echo '[Trigger]\nOperation = Upgrade\nOperation = Install\nOperation = Remove\nType = Path\nTarget = usr/lib/modules/*/vmlinuz\n\n[Action]\nDepends = rsync\nDescription = Backing up /boot...\nWhen = PreTransaction\nExec = /usr/bin/rsync -a --delete /boot /.bootbackup' | sudo tee -a /etc/pacman.d/hooks/50-bootbackup.hook > /dev/null
echo '#!/bin/bash\n/usr/bin/numlockx on\nnvidia-settings --assign CurrentMetaMode="DPY-2: 2560x1440_144 @2560x1440 +440+0 {ViewPortIn=2560x1440, ViewPortOut=2560x1440+0+0, ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}, DPY-3: 3440x1440_100 @3440x1440 +0+1440 {ViewPortIn=3440x1440, ViewPortOut=3440x1440+0+0, ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"' | sudo tee -a /etc/lightdm/monitor_numlock.sh > /dev/null
sudo chmod +x /etc/lightdm/monitor_numlock.sh
sudo sed -i 's/#greeter-setup-script=.*/greeter-setup-script=\/etc\/lightdm\/monitor_numlock.sh/' /etc/lightdm/lightdm.conf
echo '[greeter]\ncursor-theme-name = Adwaita\ncursor-theme-size = 16\ntheme-name = Arc-Dark\nicon-theme-name = Adwaita\nfont-name = Roboto 10\nindicators = ~spacer;~clock;~spacer;~language;~session;~a11y;~power' | sudo tee /etc/lightdm/lightdm-gtk-greeter.conf > /dev/null
echo 'Section "ServerFlags"\n    Option "DontVTSwitch" "True"\nEndSection' | sudo tee -a /etc/X11/xorg.conf > /dev/null

bluetoothctl power on
bluetoothctl pair DC:2C:26:FF:17:17
bluetoothctl trust DC:2C:26:FF:17:17

mkdir ~/.config/{bspwm,dunst,gtk-3.0,kitty,picom,polybar,rofi,sxhkd}
install -m644 /arch_install/.zshrc ~/.zshrc
echo 'setxkbmap se\nxrdb ~/.Xresources' | tee -a ~/.xprofile > /dev/null
echo 'Xcursor.theme: Adwaita\nXcursor.size: 16' | tee -a ~/.Xresources > /dev/null

install -Dm755 /arch_install/.config/bspwm/bspwmrc ~/.config/bspwm/bspwmrc
#echo "#! /bin/sh\n\n_() { bspc config \"\$@\";  }\n\nsxhkd &\npicom --config ~/.config/picom/picom.conf -b &\nsh ~/.config/polybar/launch.sh\nudiskie &\nlight-locker &\nxset s off\nxset dpms 0 0 0\nxautolock -time 15 -locker \"systemctl suspend\" -detectsleep &\n\nAC=\$(grep -m1 'ac = ' ~/.config/polybar/colors.ini | awk '{print \$3}')\n\nbspc wm --reorder-monitors DP-0 HDMI-0\nbspc monitor DP-0 -d 1 2\nbspc monitor HDMI-0 -d 3 4\n\n_ border_width 3\n_ window_gap 8\n_ focused_border_color \"\$AC\"\n_ normal_border_color '#171a1f'\n_ active_border_color '#171a1f'\n_ ignore_ewmh_focus true\n_ pointer_follows_monitor true\n\n_ split_ratio 0.52\n_ borderless_monocle true\n_ gapless_monocle true\n\n#bspc rule -a Gimp desktop='^5' state=floating follow=on\nbspc rule -a Google-chrome desktop='^1'\nbspc rule -a Geany desktop='^3'\nbspc rule -a firefox desktop='^1'" | tee ~/.config/bspwm/bspwmrc > /dev/null
#chmod +x ~/.config/bspwm/bspwmrc
install -Dm644 /arch_install/.config/dunst/dunstrc ~/.config/dunst/dunstrc
install -Dm644 /arch_install/.config/gtk-3.0/* -t ~/.config/gtk-3.0
install -Dm644 /arch_install/.config/kitty/* -t ~/.config/kitty
install -Dm644 /arch_install/.config/picom/picom.conf ~/.config/picom/picom.conf
install -Dm644 /arch_install/.config/polybar/* -t ~/.config/polybar
chmod +x ~/.config/polybar/launch.sh
install -Dm644 /arch_install/.config/rofi/* -t ~/.config/rofi
install -Dm644 /arch_install/.config/sxhkd/sxhkdrc ~/.config/sxhkd/sxhkdrc
install -Dm755 /arch_install/.scripts/* -t ~/.scripts
#install -Dm644 /arch_install/.mozilla/firefox/a5qjmjc5.default-release/chrome/userChrome.css ~/.mozilla/firefox/*.default-release/chrome/userChrome.css

print "All done."

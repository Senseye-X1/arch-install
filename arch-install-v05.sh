#!/usr/bin/env -S bash -e

xorgminimal="xorg-server xorg-xinit xorg-setxkbmap xorg-xsetroot xorg-xset"
xdg="xdg-user-dirs xdg-utils"
fonts="ttf-font-awesome ttf-monofur ttf-roboto ttf-iosevka-nerd ttf-ubuntu-font-family"
winmgrutils="accountsservice udiskie dunst feh firewalld gvfs kitty lxappearance-gtk3 picom xautolock geany gnome-themes-extra"
network="networkmanager"
pulseaudio="alsa-utils pulseaudio"
pipewire="alsa-utils pipewire pipewire-alsa pipewire-pulse"
browser="firefox"
basesetup="base linux linux-firmware nano sudo efibootmgr grub os-prober pacman-contrib rsync stow reflector"
btrfsutils="grub-btrfs btrfs-progs snap-pac snapper"
nvidia="nvidia nvidia-settings"

# Microcode detector (function).
microcode_detector () {
    CPU=$(grep vendor_id /proc/cpuinfo)
    if [[ $CPU == *"AuthenticAMD"* ]]; then
        echo "An AMD CPU has been detected, the AMD microcode will be installed."
        microcode="amd-ucode"
    else
        echo "An Intel CPU has been detected, the Intel microcode will be installed."
        microcode="intel-ucode"
    fi
}

# Setting up a password for the user account (function).
userpass_selector () {
while true; do
  read -r -s -p "Set a user password for $username: " password
	while [ -z "$password" ]; do
	echo
	echo "You need to enter a password for $username."
	read -r -s -p "Set a user password for $username: " password
	[ -n "$password" ] && break
	done
  echo
  read -r -s -p "Insert password again: " password2
  echo
  [ "$password" = "$password2" ] && break
  echo "Passwords don't match, try again."
done
}

# User enters a hostname (function).
hostname_selector () {
    read -r -p "Please enter the hostname: " hostname
    if [[ -z "$hostname" ]]; then
        echo
	echo "You need to enter a hostname in order to continue."
        return 1
    fi
    return 0
}

# Selecting the DE/WM for the installation (function).
winmgr_selector () {
    PS3="Please select the DE/WM: "
    select WMENTRY in bspwm dwm kde gnome;
    do
        if [[ $WMENTRY == "bspwm" ]]; then
            pacstrap /mnt bspwm sxhkd rofi polybar light-locker lightdm-gtk-greeter ${xorgminimal} ${fonts} ${winmgrutils} ${pulseaudio} ${xdg} >/dev/null
	        winmanager="bspwm"
	        systemctl enable lightdm.service --root=/mnt &>/dev/null
        else if [[ $WMENTRY == "dwm" ]]; then
            pacstrap /mnt git dmenu light-locker lightdm-gtk-greeter ${xorgminimal} ${fonts} ${winmgrutils} ${pulseaudio} ${xdg} >/dev/null
    	    winmanager="dwm"
    	    systemctl enable lightdm.service --root=/mnt &>/dev/null
        else if [[ $WMENTRY == "kde" ]]; then
            pacstrap /mnt xorg plasma kde-graphics-meta kde-multimedia-meta kde-network-meta akregator kalarm kalendar knotes korganizer kde-system-meta kde-utilities-meta >/dev/null
	        winmanager="kde"
        	systemctl enable sddm --root=/mnt &>/dev/null
        else if [[ $WMENTRY == "gnome" ]]; then
            pacstrap /mnt xorg gnome >/dev/null
	        winmanager="gnome"
	        systemctl enable gdm --root=/mnt &>/dev/null
        else
	        winmanager=""
        fi
        echo "Installed window manager $winmanager."
        break
    done
}


# Select if Bluetooth support is needed (function).
bluetooth_selector () {
    read -r -p "Install Bluetooth [y/N]? " bt
    bt=${bt,,}
    if [[ "$bt" =~ ^(yes|y)$ ]]; then
        echo
        echo "Installing Bluetooth."
        pacstrap /mnt bluez bluez-utils >/dev/null
        bluetooth="yes"
    else
        bluetooth="no"
    fi
}

# Selecting the command-line shell for the user (function).
cmdshell_selector () {
    PS3="Please select the command-line shell: "
    select SHENTRY in bash zsh;
    do
        if [[ $SHENTRY == "zsh" ]]; then
            pacstrap /mnt zsh zsh-autosuggestions zsh-completions zsh-syntax-highlighting >/dev/null
	    usershell="zsh"
        else if [[ $SHENTRY == "bash" ]]; then
            pacstrap /mnt bash-completion >/dev/null
            usershell="bash"
        else
            usershell=""
        fi
        echo "Installed user command-line shell."
        break
    done
}

# User chooses the locale (function).
locale_selector () {
    read -r -p "Please insert the locale you use (format: xx_XX. Enter empty to use en_US, or \"/\" to search locales): " locale
    case "$locale" in
        '') locale="en_US.UTF-8"
            echo "$locale will be the default locale."
            return 0;;
        '/')    sed -E '/^#( +|$)/d;s/^#| *$//g;s/ .*/      (Charset:&)/' /etc/locale.gen | less -M
                clear
                return 1;;
        *)  if ! grep -q "^#\?$(sed 's/[].*[]/\\&/g' <<< $locale) " /etc/locale.gen; then
                echo "The specified locale doesn't exist or isn't supported."
                return 1
            fi
            return 0
    esac
}

# User chooses the console keyboard layout (function).
keyboard_selector () {
    read -r -p "Please insert the keyboard layout to use in console (leave blank for sv-latin1, or \"/\" to look up keyboard layouts): " kblayout
    case "$kblayout" in
        '') kblayout="sv-latin1"
            echo "The default keyboard layout will be used."
            return 0;;
        '/') localectl list-keymaps
             clear
             return 1;;
        *) if ! localectl list-keymaps | grep -Fxq "$kblayout"; then
               echo "The specified keymap doesn't exist."
               return 1
           fi
        echo "Changing console layout to $kblayout."
        loadkeys "$kblayout"
        return 0
    esac
}

keyboard_selector

# Selecting the swaptype.
PS3="Please select the swap type: "
select SWENTRY in file ram;
do
    echo "Configuring swap in $SWENTRY."
    if [[ $SWENTRY == "ram" ]]; then
        swaptype="zram-generator"
    else
        swaptype=""
    fi
    break
done

# Selecting the target for the installation.
PS3="Please select the disk where Arch Linux is going to be installed: "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
do
    DISK=$ENTRY
    echo "Installing Arch Linux on $DISK."
    break
done

# Deleting old partition scheme.
echo
read -r -p "This will delete the current partition table on $DISK. Do you agree [y/N]? " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]; then
    echo
    echo "Wiping $DISK."
    wipefs -af "$DISK" &>/dev/null
    sgdisk -Zo "$DISK" &>/dev/null
else
    echo "Quitting."
    exit
fi

# Creating a new partition scheme.
echo "Creating the partitions on $DISK."
parted -s "$DISK" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart ARCHROOT 513MiB 100% \

ESP=$(findfs PARTLABEL=ESP)
BTRFS=$(findfs PARTLABEL=ARCHROOT)

# Informing the Kernel of the changes.
echo "Informing the Kernel about the disk changes."
partprobe "$DISK"

# Formatting the ESP as FAT32.
echo "Formatting the EFI Partition as FAT32."
mkfs.fat -F 32 $ESP &>/dev/null

# Formatting the root partition as BTRFS.
echo "Formatting the root partition as BTRFS."
mkfs.btrfs -f $BTRFS &>/dev/null
mount $BTRFS /mnt

### Creating BTRFS subvolumes for Snapper manual flat layout.
echo "Creating BTRFS subvolumes."
for volume in @ @home @root @srv @snapshots @log @pkg
do
    btrfs su cr /mnt/$volume
done

if [ $swaptype = "" ]; then
btrfs su cr /mnt/@swap
fi

# Mounting the newly created subvolumes.
umount /mnt
echo "Mounting the newly created subvolumes."
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@ $BTRFS /mnt
mkdir -p /mnt/{home,root,srv,.snapshots,/var/log,/var/cache/pacman/pkg,boot}
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@home $BTRFS /mnt/home
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@root $BTRFS /mnt/root
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@srv $BTRFS /mnt/srv
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@snapshots $BTRFS /mnt/.snapshots
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@log $BTRFS /mnt/var/log
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@pkg $BTRFS /mnt/var/cache/pacman/pkg
chattr +C /mnt/var/log
mount $ESP /mnt/boot/
if [ $swaptype = "" ]; then
    mkdir -p /mnt/swap
    mount -o subvol=@swap $BTRFS /mnt/swap
fi

# Setting username and password.
echo
read -r -p "Please enter name for a user account (leave empty to not create one): " username
userpass_selector

# Checking the microcode to install.
microcode_detector

hostname_selector

locale_selector

# Install base setup.
pacstrap /mnt ${basesetup} ${btrfsutils} ${microcode} ${nvidia} ${swaptype} ${network} ${browser} ${xdg}

winmgr_selector

cmdshell_selector

bluetooth_selector

# Generating /etc/fstab.
echo "Generating a new fstab."
genfstab -U /mnt >> /mnt/etc/fstab

# Setting up GRUB
sed -i 's/^GRUB_GFXMODE=.*/GRUB_GFXMODE=3440x1440x32/' /mnt/etc/default/grub
sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /mnt/etc/default/grub
sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT=".*\)\(.\)$/\1 nvidia-drm.modeset=1\2/' /mnt/etc/default/grub
sed -i 's/^#GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=true/' /mnt/etc/default/grub
echo 'GRUB_DISABLE_OS_PROBER=false' >> /mnt/etc/default/grub
if [ $swaptype = "zram-generator" ]; then
sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT=".*\)\(.\)$/\1 zswap.enabled=0\2/' /mnt/etc/default/grub
fi
### End creating BTRFS subvolumes for Snapper manual flat layout.

# Setting up keyboard layout.
echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf

# Setting up the hostname.
echo "$hostname" > /mnt/etc/hostname

# Setting hosts file.
echo "Setting hosts file."
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

# Setting up locale.
echo "$locale UTF-8"  > /mnt/etc/locale.gen
echo "LANG=$locale" > /mnt/etc/locale.conf

# Fix function keys on Keychron keyboards using Apple driver.
cat >> /mnt/etc/modprobe.d/hid_apple.conf <<EOF
options hid_apple fnmode=2
EOF

# Configuring /etc/mkinitcpio.conf
echo "Configuring mkinitcpio for BTRFS and NVIDIA."
#sed -i 's/#COMPRESSION=.*/COMPRESSION="zstd"/g' /mnt/etc/mkinitcpio.conf
sed -i 's/^MODULES=.*/MODULES=\(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm\)/' /mnt/etc/mkinitcpio.conf
# If using LVM add lvm2 to pacstrap and uncomment below.
#sed -i 's/\(^HOOKS.*block \)\(filesystems.*\)/\1lvm2 \2/' /mnt/etc/mkinitcpio.conf

# Configuring the system.    
arch-chroot /mnt /bin/bash -e <<EOF
    
    # Create swapfile, set No_COW, add to fstab
    if [ $swaptype = "" ]; then
    echo "Creating swapfile."
    truncate -s 0 /swap/swapfile
    chattr +C /swap/swapfile
    btrfs property set /swap/swapfile compression none
    dd if=/dev/zero of=/swap/swapfile bs=1M count=8192 status=progress
    chmod 600 /swap/swapfile
    mkswap /swap/swapfile
    swapon /swap/swapfile
    echo "/swap/swapfile none swap defaults 0 0" >> /etc/fstab
    fi

    # Setting up timezone.
    echo "Setting up timezone."
    ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime &>/dev/null
    
    timedatectl set-ntp true
    
    # Setting up clock.
    hwclock --systohc
    
    # Generating locales.
    echo "Generating locales."
    locale-gen &>/dev/null
    
    # Generating a new initramfs.
    echo "Creating a new initramfs."
    #chmod 600 /boot/initramfs-linux* &>/dev/null
    mkinitcpio -P &>/dev/null

    # Snapper configuration
    echo "Configuring Snapper."
    umount /.snapshots
    rm -r /.snapshots
    snapper --no-dbus -c root create-config /
    btrfs subvolume delete /.snapshots
    mkdir /.snapshots
    mount -a
    chmod 750 /.snapshots
    #chmod a+rx /.snapshots
    #chown :$username /.snapshots

    # Installing GRUB.
    echo "Installing GRUB."
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB &>/dev/null
    
    # Creating grub config file.
    echo "Creating GRUB config file."
    grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null

EOF

# Setting root password.
echo "Setting root password."
echo "root:$password" | arch-chroot /mnt chpasswd

# Adding user/password, change shell if zsh.
if [ -n "$username" ]; then
    echo "Adding the user $username to the system with root privilege."
    if [[ $usershell == "zsh" ]]; then
        arch-chroot /mnt useradd -m -G wheel -s /usr/bin/zsh "$username"
    else
	arch-chroot /mnt useradd -m -G wheel "$username"
    fi
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
    echo "Setting user password for $username." 
    echo "$username:$password" | arch-chroot /mnt chpasswd
fi

# Setting snapshot limits.
sed -i 's/ALLOW_USERS=""/ALLOW_USERS="'"$username"'"/' /mnt/etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' /mnt/etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' /mnt/etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="0"/' /mnt/etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/' /mnt/etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' /mnt/etc/snapper/configs/root

# Creating pacman hooks directory.
mkdir -p /mnt/etc/pacman.d/hooks

# Update initramfs after an NVIDIA driver upgrade.
cat << 'EOF' > /mnt/etc/pacman.d/hooks/nvidia.hook
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=linux

[Action]
Description=Update Nvidia module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux) exit 0; esac; done; /usr/bin/mkinitcpio -P'
EOF

# Pre-snapshot boot backup hook.
echo "Configuring boot backup when pacman transactions are made."
cat > /mnt/etc/pacman.d/hooks/04-bootbackuppre.hook <<EOF
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz

[Action]
Depends = rsync
Description = Backing up /boot (pre)...
When = PreTransaction
Exec = /usr/bin/rsync -a --delete /boot /.bootbackup
EOF

# Post-snapshot boot backup hook.
cat > /mnt/etc/pacman.d/hooks/06-bootbackuppost.hook <<EOF
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz

[Action]
Depends = rsync
Description = Backing up /boot (post)...
When = PostTransaction
Exec = /usr/bin/rsync -a --delete /boot /.bootbackup
EOF

# Monitor and LightDM setup.
if [[ "$WMENTRY" == "dwm" || "$WMENTRY" == "bspwm" ]]; then
cat > /mnt/etc/lightdm/monitor_setup.sh <<EOF
#!/bin/bash
xrandr --output DP-0 --mode 3440x1440 --rate 100 --pos 0x1440 --primary --output HDMI-0 --mode 2560x1440 --rate 144 --pos 440x0
nvidia-settings --assign CurrentMetaMode="DPY-2: 2560x1440_144 @2560x1440 +440+0 {ViewPortIn=2560x1440, ViewPortOut=2560x1440+0+0, ForceCompositionPipeline=On}, DPY-3: 3440x1440_100 @3440x1440 +0+1440 {ViewPortIn=3440x1440, ViewPortOut=3440x1440+0+0, ForceCompositionPipeline=On}"
echo "2" > /tmp/number-monitors
EOF

chmod +x /mnt/etc/lightdm/monitor_setup.sh
sed -i 's/#greeter-setup-script=.*/greeter-setup-script=\/etc\/lightdm\/monitor_setup.sh/' /mnt/etc/lightdm/lightdm.conf

cat > /mnt/etc/lightdm/lightdm-gtk-greeter.conf <<EOF
[greeter]
cursor-theme-name = Adwaita
cursor-theme-size = 24
theme-name = Arc-Dark
icon-theme-name = Adwaita
font-name = Roboto 10
indicators = ~spacer;~clock;~spacer;~language;~session;~a11y;~power
EOF

# Disallow Ctrl+Alt+Fn switching for added security
cat >> /mnt/etc/X11/xorg.conf <<EOF
Section "ServerFlags"
    Option "DontVTSwitch" "True"
EndSection
EOF
fi

# Firewall config
#firewall-cmd --add-port=1025-65535/tcp --permanent
#firewall-cmd --add-port=1025-65535/udp --permanent
#firewall-cmd --reload

# Enabling various services excluding lightdm. Lightdm will be enabled after reboot as user from install-dotfiles.sh.
echo "Enabling services."
# Use this instead if nested BTRFS layout:
#for service in NetworkManager fstrim.timer bluetooth systemd-timesyncd lightdm reflector.timer snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@var.timer btrfs-scrub@\\x2esnapshots.timer grub-btrfs.path
# Add bluetooth to the line below if needed.
for service in NetworkManager fstrim.timer systemd-timesyncd reflector.timer snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@log.timer btrfs-scrub@\\x2esnapshots.timer grub-btrfs.path
do
    systemctl enable "$service" --root=/mnt &>/dev/null
done

# ZRAM configuration.
if [ $swaptype = "zram-generator" ]; then
print "Configuring ZRAM."
cat > /mnt/etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = ram / 2
#zram-fraction = 1
#max-zram-size = 8192
EOF
systemctl enable systemd-oomd --root=/mnt &>/dev/null
fi

# Fix Keychron Bluetooth Keyboard Connection
if [ "$bluetooth" = "yes" ]; then
    sed -i 's/#AutoEnable=false/AutoEnable=true/' /mnt/etc/bluetooth/main.conf
    sed -i 's/#FastConnectable.*/FastConnectable = true/' /mnt/etc/bluetooth/main.conf
    sed -i 's/#\(ReconnectAttempts=.*\)/\1/' /mnt/etc/bluetooth/main.conf
    sed -i 's/#\(ReconnectIntervals=.*\)/\1/' /mnt/etc/bluetooth/main.conf
fi

if [ "$WMENTRY" = "dwm" ]; then
git clone https://github.com/bakkeby/dwm-flexipatch.git /mnt/tmp/dwm-flexipatch
git clone https://github.com/bakkeby/flexipatch-finalizer.git /mnt/tmp/flexipatch-finalizer
git clone https://github.com/UtkarshVerma/dwmblocks-async.git /mnt/tmp/dwmblocks-async

# Win-key as modkey.
sed -i 's/#define MODKEY Mod1Mask/#define MODKEY Mod4Mask/' /mnt/tmp/dwm-flexipatch/config.def.h

for patch in BAR_STATUSCMD_PATCH AUTOSTART_PATCH ATTACHBOTTOM_PATCH ALWAYSCENTER_PATCH TAGOTHERMONITOR_PATCH FIBONACCI_DWINDLE_LAYOUT SCRATCHPADS_PATCH BAR_HEIGHT_PATCH ROTATESTACK_PATCH VANITYGAPS_PATCH PERTAG_PATCH
do
    sed -i 's/\(.*'"$patch"'\).*/\1 1/' /mnt/tmp/dwm-flexipatch/patches.def.h
done

cat << 'EOF' > /mnt/tmp/dwmblocks-async/config.h
#define CMDLENGTH 60
#define DELIMITER "  "
#define CLICKABLE_BLOCKS

const Block blocks[] = {
	BLOCK("sb-mail",    1800, 17),
	BLOCK("sb-music",   0,    18),
	BLOCK("sb-disk",    1800, 19),
	BLOCK("sb-memory",  10,   20),
	BLOCK("sb-loadavg", 5,    21),
	BLOCK("sb-mic",     0,    26),
	BLOCK("sb-record",  0,    27),
	BLOCK("sb-audio-icons",  0,    22),
	BLOCK("sb-audio-volume", 0,    23),
	BLOCK("sb-date",    60,    24)
};
EOF

cd /mnt/tmp/dwm-flexipatch;make;cd
mkdir /mnt/tmp/dwm-finalized
cd /mnt/tmp/flexipatch-finalizer
./flexipatch-finalizer.sh -r -d /mnt/tmp/dwm-flexipatch -o /mnt/tmp/dwm-finalized
cd /mnt/tmp/dwm-finalized;make install;cd
cd /mnt/tmp/dwmblocks-async;make install;cd

cat > /mnt/usr/share/xsessions/dwm.desktop <<EOF
[Desktop Entry]
Encoding=UTF-8
Name=Dwm
Comment=Dynamic window manager
Exec=dwm
Icon=dwm
Type=XSession
EOF
fi

# User-specific configuration.
cat << 'EOF' > /mnt/home/$username/install-dotfiles.sh
#!/usr/bin/env -S bash -e

timedatectl set-ntp true
localectl set-x11-keymap se

git clone https://github.com/Senseye-X1/dotfiles.git $HOME/dotfiles
chmod +x $HOME/dotfiles/bspwm/\.config/bspwm/bspwmrc
chmod +x $HOME/dotfiles/polybar/\.config/polybar/launch.sh
chmod -R +x $HOME/dotfiles/scripts/\.scripts
cd $HOME/dotfiles
#stow */
stow bspwm
stow dunst
stow dwm
stow geany
stow gtk
stow kitty
stow picom
stow polybar
stow rofi
stow scripts
stow sxhkd
stow x
stow zsh
EOF

arch-chroot /mnt /bin/bash -e <<EOF
chown "$username:$username" "/home/$username/install-dotfiles.sh"
chmod +x "/home/$username/install-dotfiles.sh"
EOF

echo -e "All done!\numount -a\nreboot\n\nAfter reboot login as user $username and run ./install-dotfiles.sh"

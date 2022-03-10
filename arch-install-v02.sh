#!/usr/bin/env -S bash -e

#pacman -Syu
#pacman -S --noconfirm curl

#timezone="Europe/Stockholm"

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

# Setting up the hostname (function).
hostname_selector () {
    read -r -p "Please enter the hostname: " hostname
    if [ -z "$hostname" ]; then
        echo
        echo "You need to enter a hostname in order to continue."
        read -r -p "Please enter the hostname: " hostname
    fi
    echo "$hostname" > /mnt/etc/hostname
}

# Setting up the locale (function).
locale_selector () {
    read -r -p "Please insert the locale you use (format: xx_XX or enter empty to use en_US): " locale
    if [ -z "$locale" ]; then
        echo
        echo "en_US will be used as default locale."
        locale="en_US"
    fi
    echo "$locale.UTF-8 UTF-8"  > /mnt/etc/locale.gen
    echo "LANG=$locale.UTF-8" > /mnt/etc/locale.conf
}

# Setting up the keyboard layout (function).
keyboard_selector () {
    read -r -p "Please insert the keyboard layout you use (enter empty to use sv-latin1 keyboard layout): " kblayout
    if [ -z "$kblayout" ]; then
        echo
        echo "sv-latin1 keyboard layout will be used by default."
        kblayout="sv-latin1"
    fi
    loadkeys $kblayout
    echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf
}

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

### Creating BTRFS subvolumes with Snapper rollback nested layout.
#echo "Creating BTRFS subvolumes."
#btrfs su cr /mnt/@ &>/dev/null
#btrfs su cr /mnt/@/.snapshots &>/dev/null
#btrfs su cr /mnt/@/.snapshots/1/snapshot &>/dev/null
#btrfs su cr /mnt/@/boot &>/dev/null
#btrfs su cr /mnt/@/home &>/dev/null
#btrfs su cr /mnt/@/root &>/dev/null
#btrfs su cr /mnt/@/srv &>/dev/null
#btrfs su cr /mnt/@/var &>/dev/null
#btrfs su cr /mnt/@/swap &>/dev/null

#print "Creating BTRFS subvolumes."
#for volume in @ @/.snapshots @/.snapshots/1/snapshot @boot @home @root @srv @var @swap
#do
#    btrfs su cr /mnt/$volume
#done

#mkdir -p /mnt/@/.snapshots/1 &>/dev/null

## Set the default BTRFS Subvol to Snapshot 1 before pacstrapping
#btrfs subvolume set-default "$(btrfs subvolume list /mnt | grep "@/.snapshots/1/snapshot" | grep -oP '(?<=ID )[0-9]+')" /mnt

#cat << EOF >> /mnt/@/.snapshots/1/info.xml
#<?xml version="1.0"?>
#<snapshot>
#  <type>single</type>
#  <num>1</num>
#  <date>1999-03-31 0:00:00</date>
#  <description>First Root Filesystem</description>
#  <cleanup>number</cleanup>
#</snapshot>
#EOF

#chmod 600 /mnt/@/.snapshots/1/info.xml

## Mounting the newly created subvolumes.
#umount /mnt
#echo "Mounting the newly created subvolumes."
#mount -o ssd,noatime,space_cache=v2,compress=zstd:1 $BTRFS /mnt
##mkdir -p /mnt/{boot,root,home,.snapshots,srv,var}
#mkdir -p /mnt/{boot,root,home,.snapshots,srv,var,swap}
#mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@/boot $BTRFS /mnt/boot
#mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@/root $BTRFS /mnt/root 
#mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@/home $BTRFS /mnt/home
#mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@/.snapshots $BTRFS /mnt/.snapshots
#mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@/srv $BTRFS /mnt/srv
#mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,nodatacow,subvol=@/var $BTRFS /mnt/var
#mount -o defaults,noatime,subvol=@/swap $BTRFS /mnt/swap
#chattr +C /mnt/@/boot
#chattr +C /mnt/@/srv
#chattr +C /mnt/@/var
#mkdir -p /mnt/boot/efi
#mount $ESP /mnt/boot/efi

## Checking the microcode to install.
#microcode_detector

#pacstrap /mnt base linux linux-firmware $microcode btrfs-progs git nano alsa-utils base-devel efibootmgr firewalld grub grub-btrfs gvfs networkmanager bluez bluez-utils os-prober pacman-contrib pulseaudio rsync snap-pac snapper ttf-font-awesome ttf-roboto udiskie accountsservice archlinux-wallpaper bspwm dunst feh firefox geany gnome-themes-extra kitty light-locker lightdm-gtk-greeter lightdm-gtk-greeter-settings lxappearance-gtk3 picom dmenu sxhkd xautolock xorg zsh zsh-autosuggestions zsh-completions reflector nvidia nvidia-settings

## Generating /etc/fstab.
#echo "Generating a new fstab."
#genfstab -U /mnt >> /mnt/etc/fstab
#sed -i 's#,subvolid=258,subvol=/@/.snapshots/1/snapshot,subvol=@/.snapshots/1/snapshot##g' /mnt/etc/fstab

## Setting up GRUB
#sed -i 's/^GRUB_GFXMODE=.*/GRUB_GFXMODE=3440x1440x32/' /mnt/etc/default/grub
#sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /mnt/etc/default/grub
#sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT=".*\)\(.\)$/\1 nvidia-drm.modeset=1\2/' /mnt/etc/default/grub
#sed -i 's/^#GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=true/' /mnt/etc/default/grub
#echo 'GRUB_DISABLE_OS_PROBER=false' >> /mnt/etc/default/grub
#echo "" >> /mnt/etc/default/grub
#echo -e "# Booting with BTRFS subvolume\nGRUB_BTRFS_OVERRIDE_BOOT_PARTITION_DETECTION=true" >> /mnt/etc/default/grub
#sed -i 's#rootflags=subvol=${rootsubvol}##g' /mnt/etc/grub.d/10_linux

### End creating BTRFS subvolumes with Snapper rollback nested layout.

### Creating BTRFS subvolumes for Snapper manual flat layout.
echo "Creating BTRFS subvolumes."
for volume in @ @home @root @srv @snapshots @log @pkg @swap
do
    btrfs su cr /mnt/$volume
done

# Mounting the newly created subvolumes.
umount /mnt
echo "Mounting the newly created subvolumes."
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@ $BTRFS /mnt
mkdir -p /mnt/{home,root,srv,.snapshots,/var/log,/var/cache/pacman/pkg,boot,swap}
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@home $BTRFS /mnt/home
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@root $BTRFS /mnt/root
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@srv $BTRFS /mnt/srv
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@snapshots $BTRFS /mnt/.snapshots
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@log $BTRFS /mnt/var/log
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@pkg $BTRFS /mnt/var/cache/pacman/pkg
mount -o subvol=@swap $BTRFS /mnt/swap
chattr +C /mnt/var/log
mount $ESP /mnt/boot/

# Checking the microcode to install.
microcode_detector

# Install packages.
pacstrap /mnt base linux linux-firmware ${microcode} btrfs-progs git nano alsa-utils base-devel efibootmgr firewalld grub grub-btrfs gvfs networkmanager bluez bluez-utils os-prober pacman-contrib pulseaudio rsync snap-pac snapper ttf-font-awesome ttf-roboto ttf-iosevka-nerd udiskie accountsservice archlinux-wallpaper dunst feh firefox geany gnome-themes-extra kitty light-locker lightdm-gtk-greeter lxappearance-gtk3 picom rofi stow xautolock xorg zsh zsh-autosuggestions zsh-completions reflector nvidia nvidia-settings

# Selecting the window manager for the installation.
PS3="Please select the window manager: "
select WMENTRY in bspwm dwm;
do
    case $WMENTRY in 
        "bspwm")
	winmanager="bspwm"
        echo "Installing $WMENTRY."
	pacstrap /mnt bspwm sxhkd
        ;;
        "dwm")
        winmanager="dwm"
        echo "Installing $WMENTRY."
        ;;
        *)
        winmanager=""
        echo "No window manager selected."
        ;;
    esac
done

# Generating /etc/fstab.
echo "Generating a new fstab."
genfstab -U /mnt >> /mnt/etc/fstab

# Setting up GRUB
sed -i 's/^GRUB_GFXMODE=.*/GRUB_GFXMODE=3440x1440x32/' /mnt/etc/default/grub
sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /mnt/etc/default/grub
sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT=".*\)\(.\)$/\1 nvidia-drm.modeset=1\2/' /mnt/etc/default/grub
sed -i 's/^#GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=true/' /mnt/etc/default/grub
echo 'GRUB_DISABLE_OS_PROBER=false' >> /mnt/etc/default/grub
### End creating BTRFS subvolumes for Snapper manual flat layout.

# Setting up keyboard layout.
keyboard_selector

# Setting username and password.
echo
read -r -p "Please enter name for a user account (enter empty to not create one): " username
userpass_selector

# Setting up the hostname.
hostname_selector

# Setting hosts file.
echo "Setting hosts file."
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

# Setting up locale.
locale_selector

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
    echo "Creating swapfile."
    truncate -s 0 /swap/swapfile
    chattr +C /swap/swapfile
    btrfs property set /swap/swapfile compression none
    dd if=/dev/zero of=/swap/swapfile bs=1M count=8192 status=progress
    chmod 600 /swap/swapfile
    mkswap /swap/swapfile
    swapon /swap/swapfile
    echo "/swap/swapfile none swap defaults 0 0" >> /etc/fstab

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

# Adding user/password, change shell if not zsh.
if [ -n "$username" ]; then
    echo "Adding the user $username to the system with root privilege."
    arch-chroot /mnt useradd -m -G wheel -s /usr/bin/zsh "$username"
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
cat > /mnt/etc/pacman.d/hooks/nvidia.hook <<EOF
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
#echo '[Trigger]\nOperation = Upgrade\nOperation = Install\nOperation = Remove\nType = Path\nTarget = usr/lib/modules/*/vmlinuz\n\n[Action]\nDepends = rsync\nDescription = Backing up /boot...\nWhen = PreTransaction\nExec = /usr/bin/rsync -a --delete /boot /.bootbackup' | tee -a /etc/pacman.d/hooks/04-bootbackup.hook > /dev/null
cat > /mnt/etc/pacman.d/hooks/04-prebootbackup.hook <<EOF
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
cat > /mnt/etc/pacman.d/hooks/06-postbootbackup.hook <<EOF
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

# ZRAM configuration.
#print "Configuring ZRAM."
#cat > /mnt/etc/systemd/zram-generator.conf <<EOF
#[zram0]
#zram-fraction = 1
#max-zram-size = 8192
#EOF

# Monitor and LightDM setup.
cat > /mnt/etc/lightdm/monitor_setup.sh <<EOF
#!/bin/bash
nvidia-settings --assign CurrentMetaMode="DPY-2: 2560x1440_144 @2560x1440 +440+0 {ViewPortIn=2560x1440, ViewPortOut=2560x1440+0+0, ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}, DPY-3: 3440x1440_100 @3440x1440 +0+1440 {ViewPortIn=3440x1440, ViewPortOut=3440x1440+0+0, ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
EOF

chmod +x /mnt/etc/lightdm/monitor_setup.sh
sed -i 's/#greeter-setup-script=.*/greeter-setup-script=\/etc\/lightdm\/monitor_setup.sh/' /mnt/etc/lightdm/lightdm.conf
#sed -i 's/#greeter-session=.*/greeter-session=lightdm-slick-greeter/' /mnt/etc/lightdm/lightdm.conf

cat > /mnt/etc/lightdm/lightdm-gtk-greeter.conf <<EOF
[greeter]
cursor-theme-name = Adwaita
cursor-theme-size = 16
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

# Firewall config
#firewall-cmd --add-port=1025-65535/tcp --permanent
#firewall-cmd --add-port=1025-65535/udp --permanent
#firewall-cmd --reload

# Enabling various services excluding lightdm. Lightdm will be enabled after reboot as user from install-second.sh.
echo "Enabling services."
# Use this instead if nested BTRFS layout:
#for service in NetworkManager fstrim.timer bluetooth systemd-timesyncd lightdm reflector.timer snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@var.timer btrfs-scrub@\\x2esnapshots.timer grub-btrfs.path
for service in NetworkManager fstrim.timer bluetooth systemd-timesyncd reflector.timer snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@log.timer btrfs-scrub@\\x2esnapshots.timer grub-btrfs.path
do
    systemctl enable "$service" --root=/mnt &>/dev/null
done

# Fix Keychron Bluetooth Keyboard Connection
sed -i 's/#AutoEnable=false/AutoEnable=true/' /mnt/etc/bluetooth/main.conf
sed -i 's/#FastConnectable.*/FastConnectable = true/' /mnt/etc/bluetooth/main.conf
sed -i 's/#\(ReconnectAttempts=.*\)/\1/' /mnt/etc/bluetooth/main.conf
sed -i 's/#\(ReconnectIntervals=.*\)/\1/' /mnt/etc/bluetooth/main.conf

# User-specific configuration.
cat > /mnt/home/$username/install-dotfiles.sh <<EOF
#!/usr/bin/env -S bash -e

timedatectl set-ntp true
localectl set-x11-keymap se

#cd
git clone https://github.com/Senseye-X1/dotfiles.git $HOME/dotfiles
chmod +x $HOME/dotfiles/bspwm/\.config/bspwm/bspwmrc
chmod +x $HOME/dotfiles/polybar/\.config/polybar/launch.sh
chmod -R +x $HOME/dotfiles/scripts/\.scripts
cd $HOME/dotfiles
stow */

git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru;makepkg -si --noconfirm;cd

paru -S polybar --removemake

sudo systemctl enable lightdm.service
EOF

if [ "$winmanager" -eq "dwm" ]; then
sed -i 's/\(^git clone.*paru.git.*\)/#\1/' /mnt/home/$username/install-dotfiles.sh
sed -i 's/\(^cd.*makepkg -si --noconfirm.*\)/#\1/' /mnt/home/$username/install-dotfiles.sh
sed -i 's/\(^paru -S polybar --removemake\)/#\1/' /mnt/home/$username/install-dotfiles.sh

cat >> /mnt/home/$username/install-dotfiles.sh <<EOF
git clone https://github.com/bakkeby/dwm-flexipatch.git $HOME/suckless/dwm-flexipatch
git clone https://github.com/bakkeby/flexipatch-finalizer.git $HOME/suckless/flexipatch-finalizer

# Win-key as modkey.
sed -i 's/#define MODKEY Mod1Mask/#define MODKEY Mod4Mask/' /home/$username/suckless/dwm-flexipatch/config.def.h

for patch in BAR_STATUSCMD_PATCH AUTOSTART_PATCH ATTACHBOTTOM_PATCH ALWAYSCENTER_PATCH CYCLELAYOUTS_PATCH FIBONACCI_DWINDLE_LAYOUT SCRATCHPADS_PATCH BAR_HEIGHT_PATCH ROTATESTACK_PATCH VANITYGAPS_PATCH PERTAG_PATCH
do
    sed -i 's/\(.*'"$patch"'\).*/\1 1/' /home/$username/suckless/dwm-flexipatch/patches.def.h
done

cd /home/$username/suckless/dwm-flexipatch;make;cd ..
mkdir dwm-finalized
cd flexipatch-finalizer
./flexipatch-finalizer.sh -r -d $HOME/suckless/dwm-flexipatch -o $HOME/suckless/dwm-finalized


sudo cat > /usr/share/xsessions/dwm.desktop <<EOF
[Desktop Entry]
Encoding=UTF-8
Name=Dwm
Comment=Dynamic window manager
Exec=dwm
Icon=dwm
Type=XSession
EOF
EOF
fi

arch-chroot /mnt /bin/bash -e <<EOF
chown "$username:$username" "/home/$username/install-dotfiles.sh"
chmod +x "/home/$username/install-dotfiles.sh"
EOF

echo -e "All done!\numount -a\nreboot\n\nAfter reboot login as user $username and run ./install-dotfiles.sh"

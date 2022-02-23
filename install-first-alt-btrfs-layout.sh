#!/usr/bin/env -S bash -e

pacman -Syu
pacman -S --noconfirm curl

hostname="arch"
timezone="Europe/Stockholm"
keymap="sv-latin1"
#DISK="/dev/nvme1n1"
#EFI="/dev/nvme1n1p1"
#BTRFS="/dev/nvme1n1p2"

#username="andreas"
#password="password"
locale="en_US"

# Checking the microcode to install.
CPU=$(grep vendor_id /proc/cpuinfo)
if [[ $CPU == *"AuthenticAMD"* ]]; then
    microcode=amd-ucode
else
    microcode=intel-ucode
fi

# Setting up a password for the user account (function).
userpass_selector () {
while true; do
  read -r -s -p "Set a user password for $username: " password
	while [ -z "$password" ]; do
	echo
	print "You need to enter a password for $username."
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

Selecting the target for the installation.
PS3="Select the disk where Arch Linux is going to be installed: "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
do
    DISK=$ENTRY
    echo "Installing Arch Linux on $DISK."
    break
done

# Deleting old partition scheme.
read -r -p "This will delete the current partition table on $DISK. Do you agree [y/N]? " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]; then
    wipefs -af "$DISK" &>/dev/null
    sgdisk -Zo "$DISK" &>/dev/null
else
    echo "Quitting."
    exit
fi

# Creating a new partition scheme.
echo "Creating new partition scheme on $DISK."
parted -s "$DISK" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 512MiB \
    set 1 esp on \
    mkpart archroot 513MiB 100% \

ESP="/dev/disk/by-partlabel/ESP"
BTRFS="/dev/disk/by-partlabel/archroot"

# Informing the Kernel of the changes.
echo "Informing the Kernel about the disk changes."
partprobe "$DISK"

# Formatting the ESP as FAT32.
echo "Formatting the EFI Partition as FAT32."
mkfs.fat -F 32 $ESP &>/dev/null

# Formatting the root partition as BTRFS.
echo "Formatting the root partition as BTRFS."
mkfs.btrfs $BTRFS &>/dev/null
mount $BTRFS /mnt
loadkeys $keymap
#timedatectl set-ntp true
#mkfs.btrfs -f /dev/mapper/linux--vg-arch
#mount /dev/mapper/linux--vg-arch /mnt

# Working Snapper rollback.
echo "Creating BTRFS subvolumes."
btrfs su cr /mnt/@ &>/dev/null
btrfs su cr /mnt/@/.snapshots &>/dev/null
mkdir -p /mnt/@/.snapshots/1 &>/dev/null
btrfs su cr /mnt/@/.snapshots/1/snapshot &>/dev/null
btrfs su cr /mnt/@/boot &>/dev/null
btrfs su cr /mnt/@/home &>/dev/null
btrfs su cr /mnt/@/root &>/dev/null
btrfs su cr /mnt/@/srv &>/dev/null
btrfs su cr /mnt/@/var &>/dev/null
#btrfs su cr /mnt/@/swap &>/dev/null
chattr +C /mnt/@/boot
chattr +C /mnt/@/srv
chattr +C /mnt/@/var

#Set the default BTRFS Subvol to Snapshot 1 before pacstrapping
btrfs subvolume set-default "$(btrfs subvolume list /mnt | grep "@/.snapshots/1/snapshot" | grep -oP '(?<=ID )[0-9]+')" /mnt

cat << EOF >> /mnt/@/.snapshots/1/info.xml
<?xml version="1.0"?>
<snapshot>
  <type>single</type>
  <num>1</num>
  <date>1999-03-31 0:00:00</date>
  <description>First Root Filesystem</description>
  <cleanup>number</cleanup>
</snapshot>
EOF

chmod 600 /mnt/@/.snapshots/1/info.xml

# Mounting the newly created subvolumes.
umount /mnt
echo "Mounting the newly created subvolumes."
mount -o ssd,noatime,space_cache=v2,compress=zstd:1 $BTRFS /mnt
mkdir -p /mnt/{boot,root,home,.snapshots,srv,var}
#mkdir -p /mnt/{boot,root,home,.snapshots,srv,var,swap}
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@/boot $BTRFS /mnt/boot
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@/root $BTRFS /mnt/root 
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@/home $BTRFS /mnt/home
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@/.snapshots $BTRFS /mnt/.snapshots
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,subvol=@/srv $BTRFS /mnt/srv
mount -o ssd,noatime,space_cache=v2,compress=zstd:1,discard=async,nodatacow,subvol=@/var $BTRFS /mnt/var
#mount -o defaults,noatime,subvol=@/swap $BTRFS /mnt/swap

mkdir -p /mnt/boot/efi
mount $ESP /mnt/boot/efi

pacstrap /mnt base linux linux-firmware ${microcode} btrfs-progs git nano alsa-utils base-devel efibootmgr firewalld grub grub-btrfs gvfs networkmanager bluez bluez-utils os-prober pacman-contrib pulseaudio rsync snap-pac snapper ttf-font-awesome ttf-roboto udiskie accountsservice archlinux-wallpaper bspwm dunst feh firefox geany gnome-themes-extra kitty light-locker lightdm-gtk-greeter lightdm-gtk-greeter-settings lxappearance-gtk3 picom rofi sxhkd xautolock xorg zsh zsh-autosuggestions zsh-completions reflector zram-generator nvidia nvidia-settings

# Generating /etc/fstab.
echo "Generating a new fstab."
genfstab -U /mnt >> /mnt/etc/fstab
sed -i 's#,subvolid=258,subvol=/@/.snapshots/1/snapshot,subvol=@/.snapshots/1/snapshot##g' /mnt/etc/fstab

# Setting up GRUB
sed -i 's/^GRUB_GFXMODE=.*/GRUB_GFXMODE=3440x1440x32/' /mnt/etc/default/grub
sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /mnt/etc/default/grub
sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT=".*\)\(.\)$/\1 nvidia-drm.modeset=1\2/' /mnt/etc/default/grub
sed -i 's/^#GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=true/' /mnt/etc/default/grub
echo 'GRUB_DISABLE_OS_PROBER=false' >> /mnt/etc/default/grub
echo "" >> /mnt/etc/default/grub
echo -e "# Booting with BTRFS subvolume\nGRUB_BTRFS_OVERRIDE_BOOT_PARTITION_DETECTION=true" >> /mnt/etc/default/grub
sed -i 's#rootflags=subvol=${rootsubvol}##g' /mnt/etc/grub.d/10_linux

# Setting username and password.
read -r -p "Please enter name for a user account (enter empty to not create one): " username
userpass_selector

echo "$hostname" > /mnt/etc/hostname
# Setting hosts file.
echo "Setting hosts file."
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

# Setting up locales.
#read -r -p "Please insert the locale you use in this format (xx_XX): " locale
echo "$locale.UTF-8 UTF-8"  > /mnt/etc/locale.gen
echo "LANG=$locale.UTF-8" > /mnt/etc/locale.conf

echo "KEYMAP=$keymap" > /mnt/etc/vconsole.conf

# Configuring /etc/mkinitcpio.conf
echo "Configuring /etc/mkinitcpio for BTRFS and NVIDIA
sed -i 's/#COMPRESSION=.*/COMPRESSION="zstd"/g' /mnt/etc/mkinitcpio.conf
sed -i 's/^MODULES=.*/MODULES=\(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm\)/' /mnt/etc/mkinitcpio.conf
# If using LVM:
#sed -i 's/\(^HOOKS.*block \)\(filesystems.*\)/\1lvm2 \2/' /etc/mkinitcpio.conf

cat > /mnt/etc/pacman.d/hooks/nvidia.hook <<EOF
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=linux
# Change the linux part above and in the Exec line if a different kernel is used

[Action]
Description=Update Nvidia module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux) exit 0; esac; done; /usr/bin/mkinitcpio -P'
EOF

# Configuring the system.    
arch-chroot /mnt /bin/bash -e <<EOF
    
    # Create swapfile, set No_COW, add to fstab
    #echo "Creating swapfile."
    #truncate -s 0 /swap/swapfile
    #chattr +C /swap/swapfile
    #btrfs property set /swap/swapfile compression none
    #dd if=/dev/zero of=/swap/swapfile bs=1M count=8192 status=progress
    #chmod 600 /swap/swapfile
    #mkswap /swap/swapfile
    #swapon /swap/swapfile
    #echo "/swap/swapfile none swap defaults 0 0" >> /etc/fstab

    # Setting up timezone.
    echo "Setting up timezone."
    ln -sf /usr/share/zoneinfo/$timezone /etc/localtime &>/dev/null
    
    # Setting up clock.
    hwclock --systohc
    
    # Generating locales.
    echo "Generating locales."
    locale-gen &>/dev/null
    
    # Generating a new initramfs.
    echo "Creating a new initramfs."
    chmod 600 /boot/initramfs-linux* &>/dev/null
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
    sed -i 's/ALLOW_USERS=""/ALLOW_USERS="'"$username"'"/' /etc/snapper/configs/root
    sed -i 's/TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' /etc/snapper/configs/root
    sed -i 's/TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' /etc/snapper/configs/root
    sed -i 's/TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="0"/' /etc/snapper/configs/root
    sed -i 's/TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/' /etc/snapper/configs/root
    sed -i 's/TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root

    # Installing GRUB.
    echo "Installing GRUB on /boot."
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB &>/dev/null
    
    # Creating grub config file.
    echo "Creating GRUB config file."
    grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null

    timedatectl set-ntp true
    localectl set-x11-keymap se
EOF

# Setting root password.
print "Setting root password."
echo "root:$password" | arch-chroot /mnt chpasswd

# Setting user password.
if [ -n "$username" ]; then
    print "Adding the user $username to the system with root privilege."
    arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$username"
    sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /mnt/etc/sudoers
    print "Setting user password for $username." 
    echo "$username:$password" | arch-chroot /mnt chpasswd
fi

# Boot backup hook.
print "Configuring /boot backup when pacman transactions are made."
mkdir /etc/pacman.d/hooks
echo '[Trigger]\nOperation = Upgrade\nOperation = Install\nOperation = Remove\nType = Path\nTarget = usr/lib/modules/*/vmlinuz\n\n[Action]\nDepends = rsync\nDescription = Backing up /boot...\nWhen = PreTransaction\nExec = /usr/bin/rsync -a --delete /boot /.bootbackup' | tee -a /etc/pacman.d/hooks/50-bootbackup.hook > /dev/null

# ZRAM configuration.
print "Configuring ZRAM."
cat > /mnt/etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-fraction = 1
max-zram-size = 8192
EOF

# Monitor and LightDM setup.
echo '#!/bin/bash\nnvidia-settings --assign CurrentMetaMode="DPY-2: 2560x1440_144 @2560x1440 +440+0 {ViewPortIn=2560x1440, ViewPortOut=2560x1440+0+0, ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}, DPY-3: 3440x1440_100 @3440x1440 +0+1440 {ViewPortIn=3440x1440, ViewPortOut=3440x1440+0+0, ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"' | tee -a /etc/lightdm/monitor_setup.sh > /dev/null
chmod +x /etc/lightdm/monitor_setup.sh
sed -i 's/#greeter-setup-script=.*/greeter-setup-script=\/etc\/lightdm\/monitor_setup.sh/' /etc/lightdm/lightdm.conf
echo '[greeter]\ncursor-theme-name = Adwaita\ncursor-theme-size = 16\ntheme-name = Arc-Dark\nicon-theme-name = Adwaita\nfont-name = Roboto 10\nindicators = ~spacer;~clock;~spacer;~language;~session;~a11y;~power' | tee /etc/lightdm/lightdm-gtk-greeter.conf > /dev/null

# Disallow Ctrl+Alt+Fn switching for added security
echo 'Section "ServerFlags"\n    Option "DontVTSwitch" "True"\nEndSection' | tee -a /etc/X11/xorg.conf > /dev/null

# Firewall config
#firewall-cmd --add-port=1025-65535/tcp --permanent
#firewall-cmd --add-port=1025-65535/udp --permanent
#firewall-cmd --reload

# Enable Services
systemctl enable NetworkManager
systemctl enable fstrim.timer
systemctl enable bluetooth
#systemctl enable firewalld
systemctl enable systemd-timesyncd
#systemctl enable lightdm
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer
systemctl enable grub-btrfs.path
systemctl enable btrfs-scrub@-.timer
# BTRFS scrub for root should scrub the whole filesystem regardless
#systemctl enable btrfs-scrub@home.timer
#systemctl enable btrfs-scrub@var.timer
#systemctl enable btrfs-scrub@\\x2esnapshots.timer

# Enabling various services.
print "Enabling services."
for service in NetworkManager fstrim.timer bluetooth systemd-timesyncd lightdm reflector.timer snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer grub-btrfs.path systemd-oomd
do
    systemctl enable "$service" --root=/mnt &>/dev/null
done

# Fix Keychron Bluetooth Keyboard Connection
sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf
sed -i 's/#FastConnectable.*/FastConnectable = true/' /etc/bluetooth/main.conf
sed -i 's/#\(ReconnectAttempts=.*\)/\1/' /etc/bluetooth/main.conf
sed -i 's/#\(ReconnectIntervals=.*\)/\1/' /etc/bluetooth/main.conf

#useradd -m $username
#echo "$username:$password" | chpasswd
#echo "$username ALL=(ALL) ALL" | tee -a /etc/sudoers.d/$username > /dev/null

# Fetching .configs from git
git clone https://github.com/andnix/arch_install.git
#chmod +x /arch_install/install-as-root.sh
chmod +x /arch_install/install-as-user.sh

print "Exit, umount -a, reboot.\nAfter reboot login as normal user and run install-as-user.sh."

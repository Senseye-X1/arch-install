#!/bin/bash

hostname="arch"
keymap="sv-latin1"
EFI="/dev/nvme1n1p1"
BTRFS="/dev/nvme1n1p2"

username="andreas"
password="password"

loadkeys $keymap
pacman -Syy
timedatectl set-ntp true
mkfs.fat -F 32 $EFI
mkfs.btrfs -f $BTRFS
mount $BTRFS /mnt
#mkfs.btrfs -f /dev/mapper/linux--vg-arch
#mount /dev/mapper/linux--vg-arch /mnt

# Creating BTRFS subvolumes.
print "Creating BTRFS subvolumes."
#for volume in @ @home @root @opt @srv @snapshots @var_log @pkg @swap
for volume in @ @home @root @opt @srv @snapshots @var @swap
do
    btrfs su cr /mnt/$volume
done

umount /mnt
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@ $BTRFS /mnt
mkdir -p /mnt/{boot,home,root,opt,srv,.snapshots,var,swap}
#mkdir -p /mnt/{boot,home,root,opt,srv,.snapshots,var/log,var/cache/pacman/pkg,swap}
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@home $BTRFS /mnt/home
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@root $BTRFS /mnt/root
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@opt $BTRFS /mnt/opt
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@srv $BTRFS /mnt/srv
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@snapshots $BTRFS /mnt/.snapshots
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@var $BTRFS /mnt/var
#mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@var_log $BTRFS /mnt/var/log
#mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@pkg $BTRFS /mnt/var/cache/pacman/pkg
mount -o defaults,noatime,subvol=@swap $BTRFS /mnt/swap
chattr +C /mnt/var
#chattr +C /mnt/var/log
#chattr +C /mnt/cache/pacman/pkg

mount $EFI /mnt/boot
pacstrap /mnt base linux linux-firmware amd-ucode btrfs-progs git nano
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

# Create swapfile, set No_COW, add to fstab
prinf "Create swapfile"
truncate -s 0 /swap/swapfile
chattr +C /swap/swapfile
btrfs property set /swap/swapfile compression none
dd if=/dev/zero of=/swap/swapfile bs=1M count=8192 status=progress
chmod 600 /swap/swapfile
mkswap /swap/swapfile
swapon /swap/swapfile
echo "/swap/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab

# Fetching .configs from git
git clone https://github.com/andnix/arch_install.git
#chmod +x /arch_install/install-as-root.sh
chmod +x /arch_install/install-as-user.sh

#timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' | tee -a /etc/locale.conf > /dev/null
echo "KEYMAP=$keymap" | tee -a /etc/vconsole.conf > /dev/null
localectl set-x11-keymap se
echo "$hostname" | tee -a /etc/hostname > /dev/null
echo "127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$hostname.localdomain	$hostname" | tee -a /etc/hosts > /dev/null
echo "root:$password" | chpasswd

pacman -S alsa-utils base-devel efibootmgr firewalld grub grub-btrfs gvfs networkmanager bluez bluez-utils os-prober pacman-contrib pulseaudio rsync snap-pac snapper ttf-font-awesome ttf-roboto udiskie accountsservice archlinux-wallpaper bspwm dunst feh firefox geany gnome-themes-extra kitty light-locker lightdm-gtk-greeter lightdm-gtk-greeter-settings lxappearance-gtk3 picom rofi sxhkd xautolock xorg zsh zsh-autosuggestions zsh-completions
pacman -S --noconfirm nvidia nvidia-settings

# Modules for BTRFS and NVIDIA
sed -i 's/^MODULES=.*/MODULES=\(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm\)/' /etc/mkinitcpio.conf

# If using LVM
#sed -i 's/\(^HOOKS.*block \)\(filesystems.*\)/\1lvm2 \2/' /etc/mkinitcpio.conf

mkinitcpio -P

# Setting up GRUB
sed -i 's/^GRUB_GFXMODE=.*/GRUB_GFXMODE=3440x1440x32/' /etc/default/grub
sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT=".*\)\(.\)$/\1 nvidia-drm.modeset=1\2/' /etc/default/grub
sed -i 's/^#GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=true/' /etc/default/grub
echo 'GRUB_DISABLE_OS_PROBER=false' | tee -a /etc/default/grub > /dev/null

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

print "Configuring Snapper."
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

# Boot backup hook.
print "Configuring /boot backup when pacman transactions are made."
mkdir /etc/pacman.d/hooks
echo '[Trigger]\nOperation = Upgrade\nOperation = Install\nOperation = Remove\nType = Path\nTarget = usr/lib/modules/*/vmlinuz\n\n[Action]\nDepends = rsync\nDescription = Backing up /boot...\nWhen = PreTransaction\nExec = /usr/bin/rsync -a --delete /boot /.bootbackup' | tee -a /etc/pacman.d/hooks/50-bootbackup.hook > /dev/null

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
# BTRFS scrub should scrub the whole filesystem regardless
#systemctl enable btrfs-scrub@home.timer
#systemctl enable btrfs-scrub@var.timer
#systemctl enable btrfs-scrub@\\x2esnapshots.timer

# Fix Keychron Bluetooth Keyboard Connection
sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf
sed -i 's/#FastConnectable.*/FastConnectable = true/' /etc/bluetooth/main.conf
sed -i 's/#\(ReconnectAttempts=.*\)/\1/' /etc/bluetooth/main.conf
sed -i 's/#\(ReconnectIntervals=.*\)/\1/' /etc/bluetooth/main.conf

useradd -m $username
echo "$username:$password" | chpasswd
echo "$username ALL=(ALL) ALL" | tee -a /etc/sudoers.d/$username > /dev/null

print "Exit, umount -a, reboot.\nAfter reboot login as normal user and run install-as-user.sh."

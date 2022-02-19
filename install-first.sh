#!/bin/bash

EFI="/dev/nvme1n1p1"
BTRFS="/dev/nvme1n1p2"

username="andreas"
userpass="password"

loadkeys sv-latin1
pacman -Syy
timedatectl set-ntp true
mkfs.fat -F 32 $EFI
#mkfs.btrfs -f $BTRFS
#mount $BTRFS /mnt
mkfs.btrfs -f /dev/mapper/linux--vg-arch
mount /dev/mapper/linux--vg-arch /mnt

# Creating BTRFS subvolumes.
print "Creating BTRFS subvolumes."

#for volume in @ @home @root @opt @srv @snapshots @var @swap
#do
#    btrfs su cr /mnt/$volume
#done

#umount /mnt
#mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@ $BTRFS /mnt
#mkdir -p /mnt/{boot,home,root,opt,srv,.snapshots,var,swap}
#mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@home $BTRFS /mnt/home
#mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@root $BTRFS /mnt/root
#mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@opt $BTRFS /mnt/opt
#mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@srv $BTRFS /mnt/srv
#mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@snapshots $BTRFS /mnt/.snapshots
#mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@var $BTRFS /mnt/var
#mount -o subvol=@swap $BTRFS /mnt/swap
#chattr +C /mnt/var

#btrfs subvolume create /mnt/@
#btrfs subvolume create /mnt/@home
#btrfs subvolume create /mnt/@snapshots
#btrfs subvolume create /mnt/@var_log
#btrfs subvolume create /mnt/@pkg

for volume in @ @home @root @opt @srv @snapshots @var_log @pkg
do
    btrfs su cr /mnt/$volume
done

umount /mnt
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@ /dev/mapper/linux--vg-arch /mnt
mkdir -p /mnt/{boot,home,root,opt,srv,.snapshots,var/log,var/cache/pacman/pkg}
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@home /dev/mapper/linux--vg-arch /mnt/home
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@root /dev/mapper/linux--vg-arch /mnt/root
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@opt /dev/mapper/linux--vg-arch /mnt/opt
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@srv /dev/mapper/linux--vg-arch /mnt/srv
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@snapshots /dev/mapper/linux--vg-arch /mnt/.snapshots
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@var_log /dev/mapper/linux--vg-arch /mnt/var/log
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@pkg /dev/mapper/linux--vg-arch /mnt/var/cache/pacman/pkg
chattr +C /mnt/var/log

mount /dev/nvme1n1p1 /mnt/boot
swapon /dev/mapper/linux--vg-swap
pacstrap /mnt base linux linux-firmware amd-ucode btrfs-progs git nano
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

# Create swapfile, set No_COW, add to fstab
#truncate -s 0 /swap/swapfile
#chattr +C /swap/swapfile
#btrfs property set /swap/swapfile compression none
#dd if=/dev/zero of=/swap/swapfile bs=1M count=8192 status=progress
#chmod 600 /swap/swapfile
#mkswap /swap/swapfile
#swapon /swap/swapfile
#echo "/swap/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab

git clone https://github.com/andnix/arch_install.git
chmod +x /arch_install/install-as-root.sh
chmod +x /arch_install/install-as-user.sh

#timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' | tee -a /etc/locale.conf > /dev/null
echo 'KEYMAP=sv-latin1' | tee -a /etc/vconsole.conf > /dev/null
localectl set-x11-keymap se
echo 'arch' | tee -a /etc/hostname > /dev/null
echo '127.0.0.1	localhost\n::1		localhost\n127.0.1.1	arch.localdomain	arch' | tee -a /etc/hosts > /dev/null
echo 'root:password' | chpasswd

pacman -S  alsa-utils base-devel efibootmgr firewalld grub grub-btrfs gvfs lvm2 networkmanager bluez bluez-utils os-prober pacman-contrib pulseaudio rsync snap-pac snapper ttf-font-awesome ttf-roboto udiskie
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

# Enable Services
systemctl enable NetworkManager
systemctl enable fstrim.timer
systemctl enable bluetooth
systemctl enable firewalld
systemctl enable systemd-timesyncd

# Fix Keychron Bluetooth Keyboard Connection
sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf
sed -i 's/#FastConnectable.*/FastConnectable = true/' /etc/bluetooth/main.conf
sed -i 's/#\(ReconnectAttempts=.*\)/\1/' /etc/bluetooth/main.conf
sed -i 's/#\(ReconnectIntervals=.*\)/\1/' /etc/bluetooth/main.conf

useradd -m andreas
echo "$username:$userpass" | chpasswd
echo "$username ALL=(ALL) ALL" | tee -a /etc/sudoers.d/andreas > /dev/null

printf "Exit, umount -a, reboot.\nAfter reboot login as normal user and run install-as-user.sh"

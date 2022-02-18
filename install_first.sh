#!/bin/bash

loadkeys sv-latin1
timedatectl set-ntp true
mkfs.fat -F 32 /dev/nvme1n1p1 
mkfs.btrfs -f /dev/mapper/linux--vg-arch 
mount /dev/mapper/linux--vg-arch /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@pkg
umount /mnt
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@ /dev/mapper/linux--vg-arch /mnt
mkdir -p /mnt/{boot,home,.snapshots,var/log,var/cache/pacman/pkg}
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@home /dev/mapper/linux--vg-arch /mnt/home
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@snapshots /dev/mapper/linux--vg-arch /mnt/.snapshots
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@var_log /dev/mapper/linux--vg-arch /mnt/var/log
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@pkg /dev/mapper/linux--vg-arch /mnt/var/cache/pacman/pkg
mount /dev/nvme1n1p1 /mnt/boot
swapon /dev/mapper/linux--vg-swap
pacstrap /mnt base linux linux-firmware amd-ucode btrfs-progs git nano
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

git clone https://github.com/andnix/arch_install.git
nano /arch_install/install.uefi (change password for root and user)
chmod +x /arch_install/install-uefi.sh
chmod +x /arch_install/install-bspwm.sh
./arch_install/install_uefi.sh

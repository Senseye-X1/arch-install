#!/bin/bash

timedatectl set-ntp true
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
sed -i 's/^MODULES=.*/MODULES=\(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm\)/' /etc/mkinitcpio.conf
sed -i 's/\(^HOOKS.*block \)\(filesystems.*\)/\1lvm2 \2/' /etc/mkinitcpio.conf
sed -i 's/^GRUB_GFXMODE=.*/GRUB_GFXMODE=3440x1440x32/' /etc/default/grub
sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
sed -i 's/^#GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=true/' /etc/default/grub
echo 'GRUB_DISABLE_OS_PROBER=false' | tee -a /etc/default/grub > /dev/null

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
systemctl enable fstrim.timer
systemctl enable bluetooth
systemctl enable firewalld
systemctl enable systemd-timesyncd

useradd -m andreas
echo 'andreas:password' | chpasswd

echo 'andreas ALL=(ALL) ALL' | tee -a /etc/sudoers.d/andreas > /dev/null

printf "Do exit, umount -a and reboot."

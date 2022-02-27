

git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si --noconfirm
cd

paru polybar

sudo systemctl enable lightdm

echo "All done!

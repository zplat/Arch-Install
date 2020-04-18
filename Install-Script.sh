#!/usr/bin/env sh

# set hostname
echo "What is the hostname"
read Computer-name
echo $Computer-name > /etc/hostname

# change shell to zsh
chsh -s /bin/zsh

# set timezone and sync clock
ln -sf /usr/share/zoneinfo/Europe/Isle_of_Man /etc/localtime

hwclock --systohc --utc

# set locales aed update locales
echo "de_DE.UTF-8 UTF-8
en_GB.UTF-8 UTF-8
en_US.UTF-8 UTF-8
es_ES.UTF-8 UTF-8
fr_FR.UTF-8 UTF-8
it_IT.UTF-8 UTF-8
ja_JP.UTF-8 UTF-8
ko_KR.UTF-8 UTF-8
pt_BR.UTF-8 UTF-8
pt_PT.UTF-8 UTF-8" >> /etc/locale.gen

locale-gen

# Set default locale
echo "LANG=en_US.UTF-8
LC_COLLATE=C" > /etc/locale.conf

# Set hosts file
echo "127.0.0.1 localhost
::1 localhost
127.0.1.1 $Computer-name.localdomain $Computer-name" >> /etc/hosts

# Set root password
echo "root password"
passwd

##################################################
# Enable repositories Multlib and AUR


echo "Enable repositories Multlib and AUR"
# [Multilib]
sed -i 's/^#\[multilib\]/\[multilib]/' /etc/pacman.conf
sed -i '/^\[multilib\]/ {n;s/^#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/}' /etc/pacman.conf

# [archlinuxfr]
sed -i 's/^#\[custom\]/\[archlinuxfr\]/' /etc/pacman.conf
sed -i '/^\[archlinuxfr\]/ {n; s/^#Sig.*$/SigLevel = Never/}' /etc/pacman.conf
sed -i '/^SigLevel.*$ /n; s/^#Server.*$/Server = http:\/\/repo.archlinux.fr\/$arch/' /etc/pacman.conf



##################################################
# update mkinitcpio.conf
sed -i 's/^HOOKS.*$/HOOKS=(base systemd autodetect modconf block sd-encrypt btrfs resume filesystems keyboard fsck)/' /etc/mkinitcpio.conf
#Update mkinitcpio

# Generate the ramdisks using the presets
mkinitcpio -p linux

# systemd-boot
bootctl --path=/boot install

# create file arch.conf
echo  "title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options rd.luks.name=$(blkid -s UUID -o value /dev/$Drive)=btrfs-system luks.options=discard root=/dev/mapper/btrfs-system rw rootflags=subvol=root quiet
"

echo "timeout 3
default arch" > /boot/loader/loader.conf

##################################################
# Add user

echo "Add user"
echo "What is the user name?"
read User-name
useradd -m -g users -s /bin/zsh $User-name



echo "Set user password"
passwd  $User-name


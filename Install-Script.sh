#!/usr/bin/env sh


##################################################
# set hostname

echo "
????????????????????
What is the hostname
####################
"

read computerName
echo $computerName > /etc/hostname


##################################################
# change shell to zsh

echo "
????????????????????
Change shell to zsh
####################
"

chsh -s /bin/zsh


##################################################
# set timezone and sync clock 

echo "
????????????????????
Set timezone and sync clock
####################
"

ln -sf /usr/share/zoneinfo/Europe/Isle_of_Man /etc/localtime

hwclock --systohc --utc

timedatectl set-ntp true

##################################################
# set locales aed update locales

echo "
????????????????????
Set locales aed update locales
####################
"

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

##################################################
# Set default locale

echo "
????????????????????
Set default locale
####################
"

echo "LANG=en_US.UTF-8
LC_COLLATE=C" > /etc/locale.conf


##################################################
# Set hosts file

echo "
????????????????????
Set hosts file
####################
"

echo "127.0.0.1 localhost
::1 localhost
127.0.1.1 $computerName.localdomain $computerName" >> /etc/hosts


##################################################
# Set root password
echo "
????????????????????
Set root password
####################
"

passwd

##################################################
# Enable repositories Multlib and AUR

echo "
????????????????????
Enable repositories Multlib and AUR
####################
"

# [Multilib]
sed -i 's/^#\[multilib\]/\[multilib]/' /etc/pacman.conf
sed -i '/^\[multilib\]/ {n;s/^#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/}' /etc/pacman.conf

# [archlinuxfr]
sed -i 's/^#\[custom\]/\[archlinuxfr\]/' /etc/pacman.conf
sed -i '/^\[archlinuxfr\]/ {n; s/^#Sig.*$/SigLevel = Never/}' /etc/pacman.conf
sed -i '/^SigLevel.*$ /n; s/^#Server.*$/Server = http:\/\/repo.archlinux.fr\/$arch/' /etc/pacman.conf


##################################################
# update mkinitcpio.conf
echo "
????????????????????
Update mkinitcpio.conf
####################
"

sed -i 's/^HOOKS.*$/HOOKS=(base systemd autodetect modconf block sd-encrypt btrfs resume filesystems keyboard fsck)/' /etc/mkinitcpio.conf

#Update mkinitcpio
# Generate the ramdisks using the presets

echo "
????????????????????
Update mkinitcpio
####################
"

mkinitcpio -p linux

##################################################
# systemd-boot

echo "
????????????????????
Systemd-boot
####################
"

bootctl --path=/boot install


DIRECTORY=/etc/pacman.d/hooks
if [[ ! -f $DIRECTORY ]]
  then
    mkkdir $DIRECTORY
  fi
 
echo "[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot...
When = PostTransaction
Exec = /usr/bin/bootctl update" > /etc/pacman.d/hooks/100-systemd-boot.hook

# create file arch.conf

echo  "title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options rd.luks.name=$(blkid -s UUID -o value /dev/$Drive)=btrfs-system luks.options=discard root=/dev/mapper/btrfs-system rw rootflags=subvol=root quiet
" > /boot/loader/entries/arch.conf

echo "timeout 3
default arch" > /boot/loader/loader.conf

##################################################
# setup user account and password

echo "
????????????????????
Setup user account and password
####################
"

echo "What is the user name?"
read userName


useradd -m -g users -s /bin/zsh $userName

echo "
????????????????????
Set user password
####################
"
passwd  $userName

##################################################
# Install reflector, Update mirrors, install sytemctl script to update mirrors when mirrorlist changes

echo "
????????????????????
Update mirrors
####################
"

pacman -S reflector

echo '[Trigger]
Operation = Upgrade
Type = Package
Target = pacman-mirrorlist

[Action]
Description = Updating pacman-mirrorlist with reflector and removing pacnew...
When = PostTransaction
Depends = reflector
Exec = /bin/sh -c "reflector --country 'United Kingdom' --latest 10 --age 24 --sort rate --save /etc/pacman.d/mirrorlist; rm -f /etc/pacman.d/mirrorlist.pacnew"' > /etc/pacman.d/hooks/mirrorupgrade.hook 

reflector --country 'United Kingdom' --latest 10 --age 24 --sort rate --save /etc/pacman.d/mirrorlist; rm -f /etc/pacman.d/mirrorlist.pacnew


##################################################
# install graphics

echo "
????????????????????
Installing graphics
####################
"

pacman -S xorg-server xorg-apps xorg-xinit xorg-xrandr 
pacman -S mesa xf86-video-amdgpu vulkan-radeon lib32-mesa
pacman -S xorg-twm

##################################################
# install ssh

echo "
????????????????????
Install ssh
####################
"

pacman -S openssh

groupadd -r ssh
gpasswd -a $userName ssh
echo 'AllowGroups ssh' >> /etc/ssh/sshd_config

##################################################
# enable ssd and networkmanager on systemctl 

echo "
????????????????????
Enable ssd and networkmanager on systemctl
####################
"

systemctl enable NetworkManager.Service
systemctl enable fstrim.timer
systemctl enable sshd.service
systemctl enable systemd-timesyncd.service

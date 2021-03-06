#!/usr/bin/env sh
# set constants
ROOTDRIVE="/dev/sdax"
BOOTDRIVE="/dev/sdax"
USER_NAME=""
TIMEZONE="Europe/London"
HOSTNAME=""
CONSOLE_KEYMAP="KEYMAP=us"
CONSOLE_FONT="FONT=sun12x22"
HOME="/home/$USER_NAME"

##################################################
# set hostname
##################################################

echo "
    ????????????????????
    What is the hostname
    ####################
"
echo "$HOSTNAME" > /etc/hostname


##################################################
# change shell to zsh
##################################################

echo "
    ????????????????????
    Change shell to zsh
    ####################
"
chsh -s /bin/zsh

##################################################
# set timezone and sync clock
##################################################

echo "
    ????????????????????
    Set timezone and sync clock
    ####################
"

ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime

hwclock --systohc

timedatectl set-ntp true

##################################################
# set locales aed update locales
##################################################

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
pt_BR.UTF-8 UTF-8" >> /etc/locale.gen

locale-gen

##################################################
# Set default locale
##################################################

echo "
    ????????????????????
    Set default locale
    ####################
"

echo "LANG=en_US.UTF-8
LC_COLLATE=C" > /etc/locale.conf

# set font for console
echo "$CONSOLE_KEYMAP" >> /etc/vconsole.conf
echo "$CONSOLE_FONT" >> /etc/vconsole.conf

##################################################
# Set hosts file
##################################################

echo "
    ????????????????????
    Set hosts file
    ####################
"

echo "127.0.0.1 localhost
::1 localhost
127.0.1.1 ${HOSTNAME}.localdomain $HOSTNAME" >> /etc/hosts


##################################################
# Set root password
##################################################
echo "
    ????????????????????
    Set root password
    ####################
"
passwd

##################################################
# Enable repositories Multlib and AUR
##################################################
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

pacman -Syu

##################################################
# update mkinitcpio.conf
##################################################
echo "
    ????????????????????
    Update mkinitcpio.conf
    ####################
"

sed -i 's/^HOOKS.*$/HOOKS=(base systemd autodetect modconf block sd-encrypt btrfs resume filesystems keyboard fsck)/' /etc/mkinitcpio.conf

##################################################
# Update mkinitcpio
# Generate the ramdisks using the presets
##################################################
echo "
    ????????????????????
    Update mkinitcpio
    ####################
"

mkinitcpio -p linux

##################################################
# systemd-boot
# Enable update
##################################################
echo "
    ????????????????????
    Systemd-boot
    ####################
"
pwd=$PWD
bootctl --path=/boot install

##################################################
# Pacman
# Create hooks folder
# Enable update of bootloader
##################################################
DIRECTORY=/etc/pacman.d/hooks
if [[ ! -d $DIRECTORY ]]
  then
    mkkdir -p $DIRECTORY
  fi

echo "[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot...
When = PostTransaction
Exec = /usr/bin/bootctl update" > /etc/pacman.d/hooks/100-systemd-boot.hook

##################################################
# create file arch.conf
# setup arch.conf
# setup loader.conf
##################################################
echo  "title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options rd.luks.name=$(blkid -s UUID -o value $ROOTDRIVE)=btrfs-system luks.options=discard root=/dev/mapper/btrfs-system rw rootflags=subvol=root quiet
" > /boot/loader/entries/arch.conf

echo "timeout 3
default arch" > /boot/loader/loader.conf

##################################################
# setup user account and password
##################################################
echo "
    ????????????????????
    Setup user account and password
    ####################
"

echo "What is the user name?"
read userName


useradd -m -g users -s /bin/zsh $USER_NAME

echo "
    ????????????????????
    Set user password
    ####################
"
passwd  $USER_NAME

##################################################
# Install reflector, Update mirrors, install sytemctl
# script to update mirrors when mirrorlist changes
##################################################
echo "
    ????????????????????
    Update mirrors 
    Install reflector
    Automate process
    ####################
"

pacman -S reflector

echo "--country 'United Kingdom' 
--latest 10 
--age 24 
--sort rate 
"
>> /etc/xdg/reflector/reflector.conf

echo "
    ????????????????????
    Update mirrors
    ####################
"

##############################
# List all packages
# Create a file in $USER
# .config/Packages
# folder.
##############################
echo "
    ????????????????????
    Update list of installed
    packages
    ####################

"
# list of Standard programs
echo "[Trigger]
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
When = PostTransaction
Exec = /bin/sh -c '/usr/bin/pacman -Qqn $HOME/.config/Packages/.nativepkglist.txt'
" > /etc/pacman.d/hooks/pkgOfficial.hook

# list of AUR programs

echo "[Trigger]
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
When = PostTransaction
Exec = /bin/sh -c '/usr/bin/pacman -Qqm $HOME/.config/Packages/.aurpkglist.txt'

" > /etc/pacman.d/hooks/pkgAUR.hook

# list of orphan apps to remove
echo "[Trigger]

Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
When = PostTransaction
Exec = /usr/bin/bash -c "/usr/bin/pacman -Qtd $HOME/.config/Packages/.orphanpkglist.txt || /usr/bin/echo '=> None found.'"" > /etc/pacman.d/hooks/pkglist.hook
" > /etc/pacman.d/hooks/pkgClean.hook


##############################
#
##############################

##################################################
# install graphics
##################################################
echo "
    ????????????????????
    Installing graphics
    ####################
"

pacman -S xorg-server xorg-apps xorg-xinit amd-ucode linux-headers x86-input-synaptics
pacman -S mesa xf86-video-amdgpu vulkan-radeon lib32-mesa lib32-vulkan-radeon
pacman -S xorg-twm xterm xorg-xclock

##################################################
# install ssh
##################################################
echo "
    ????????????????????
    Install ssd and remove
    root access, assign to
    use through ssh group.
    ####################
"
pacman -S openssh
groupadd -r ssh
gpasswd -a $userName ssh
echo 'AllowGroups ssh' >> /etc/ssh/sshd_config

##################################################
# enable ssd and networkmanager on systemctl
##################################################
echo "
    ????????????????????
    Enable ssd and
    networkmanager on
    systemctl
    ####################
"

systemctl enable NetworkManager.service
systemctl enable fstrim.timer
systemctl enable sshd.service
systemctl enable systemd-timesyncd.service
systemctl enable reflector.timer
systemctl start reflector.service

shred -u shell.sh

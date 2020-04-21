#!/usr/bin/env sh

# set url for github download
setupurl=https://raw.githubusercontent.com/zplat/Arch-Install/master/Install-Script.sh


# capture user input
# partition names
echo "Which drive is root drive"
read Drive

echo "Which drive is boot drive"
read Boot

# Encrypt disk/partition
echo "Encrypt disk/partition"
alias cmd1='cryptsetup --hash=sha512 --cipher=twofish-xts-plain64 --key-size=512 -i 30000 luksFormat /dev/$Drive'

until cmd1; do
  cmd1
done

# open btrfs container 
echo " Open root btrfs container"
alias cmd2='cryptsetup --allow-discards --persistent open /dev/$Drive btrfs-system'

until cmd2; do
  cmd2
done

# Format both boot and root partition
echo "Format both boot and root partition"
mkfs.vfat -F32 /dev/$Boot
mkfs.btrfs -L btrfs /dev/mapper/btrfs-system

# Create btrfs subvolumes 
echo "Creating btrfs subvolumes"
mount /dev/mapper/btrfs-system /mnt
btrfs  subvolume create /mnt/root
btrfs  subvolume create /mnt/home
btrfs  subvolume create /mnt/swap

umount /mnt

mount -o subvol=root,ssd,compress=lzo,discard /dev/mapper/btrfs-system /mnt
mkdir /mnt/{boot,home,swap}
mount -o subvol=home,ssd,compress=lzo,discard /dev/mapper/btrfs-system /mnt/home
mount -o subvol=swap,ssd,discard /dev/mapper/btrfs-system /mnt/swap

# create the swap
echo "Creating the swap"
truncate -s 0 /mnt/swap/swapfile
chattr +C /mnt/swap/swapfile

dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=8192 status=progress

chmod 600  /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
swapon /mnt/swap/swapfile

# mount boot volume
echo "Mount boot volume"
mount /dev/$Boot  /mnt/boot

# installation 
echo "Install packages"
pacstrap /mnt base base-devel git btrfs-progs efibootmgr zsh zsh-completions linux linux-firmware networkmanager

# generate fstab
echo "Update fstab"
genfstab -U /mnt > /mnt/etc/fstab

# log into chroot
echo "Install next script"
curl --url $setupurl > /mnt/shell.sh 

echo "Boot into chroot"
arch-chroot /mnt /bin/zsh shell1.sh

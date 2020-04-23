#!/usr/bin/env sh

# set url for github download
SETUP_URL=https://raw.githubusercontent.com/zplat/Arch-Install/master/Install-Script.sh
# set constants

# create temporary file to hold the following data
echo "ROOTDRIVE="/dev/sdax"
BOOTDRIVE="/dev/sdax"
DRIVE_PASSPHRASE=""
" > data

nano data   # fill in the blanks and save
source data   # call file

##############################################################################################
#  Set fontsize. Update mirrorlist. Update time sync.
###############################################################################################
Setup_Font() {
  echo "
  ????????????????????
  Increase font size
  ####################
  "
  setfont sun12x22
}

Update_Mirrors() {
  echo "
  ????????????????????
  Sync for faster downloads
  ####################
  "
  pacman -Syyy
  pacman -S reflector
  reflector -c "United Kingdom" -a 6 --sort rate --save /etc/pacman.d/mirrorlist
  pacman -Syyy
}

Sync_Time() {
  echo "
  ????????????????????
  Network time protocol sync
  ####################
  "
  timedatectl set-ntp true
}

# capture user input
# partition names

##############################################################################################
#  Encrypt main partition. Open encrypted container.
###############################################################################################
# Encrypt btrfs container 
Encrypt_Drive() {
  echo "
  ????????????????????
  Encrypt disk/partition
  ####################
  "
  local Drive="$1"; shift
  local Pass="$y1"; shift
  
  echo -en "$Pass" | cryptsetup --hash=sha512 --cipher=twofish-xts-plain64 --key-size=512 -i 30000 luksFormat "$Drive"
}

# open btrfs container 
Open_Root_Container() {
  echo "
  ????????????????????
  Open root btrfs container
  ####################
  " 
 local Drive="$1"; shift
 local Pass="$1"; shift
  
 echo -en "Pass" | cryptsetup --allow-discards --persistent open "$Drive" btrfs-system
}

##############################################################################################
#  Format drives both main and boot. Create BTRFS Volumes. Mount BTRFS Volumes
###############################################################################################

# Format boot partition
Format_Boot() {
  echo "
    ????????????????????
    Format boot partition
    ####################
  " 
  local Drive="$1"; shift
  mkfs.vfat -F32 "$Drive"
}

# Format root partition
Format_Root() {
  echo "
    ????????????????????
    Format root partition
    ####################
  " 
  mkfs.btrfs -L btrfs /dev/mapper/btrfs-system
}


# Create btrfs subvolumes 
Create_BTRFS_Volumes() {
  echo "
    ????????????????????
    Creating btrfs subvolumes
    ####################
  "
  mount /dev/mapper/btrfs-system /mnt
  btrfs  subvolume create /mnt/root
  btrfs  subvolume create /mnt/home
  btrfs  subvolume create /mnt/swap
  umount /mnt
  mount -o subvol=root,ssd,compress=lzo,discard /dev/mapper/btrfs-system /mnt
  mkdir /mnt/{boot,home,swap}
  mount -o subvol=home,ssd,compress=lzo,discard /dev/mapper/btrfs-system /mnt/home
  mount -o subvol=swap,ssd,discard /dev/mapper/btrfs-system /mnt/swap
}

##############################################################################################
#  Create swapfile
############################################################################################### 
Create_Swapfile() {
  # create the swap
  echo "
    ????????????????????
    Creating the swap
    ####################
  "
  truncate -s 0 /mnt/swap/swapfile
  chattr +C /mnt/swap/swapfile
  dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=8192 status=progress
  chmod 600  /mnt/swap/swapfile
  mkswap /mnt/swap/swapfile
  swapon /mnt/swap/swapfile
}

##############################################################################################
#  Mount the boot drive
###############################################################################################
Boot_Mount() {
  # mount boot volume
  echo "
    ????????????????????
    Mount boot volume
    ####################
  "
  local Boot="$1"; shift
  mount "$Boot"  /mnt/boot
}

##############################################################################################
#  Install first applications
###############################################################################################
Installation() {
  # installation 
  echo "
  ????????????????????
  Install packages
  ####################
  "
  pacstrap /mnt base base-devel git btrfs-progs efibootmgr zsh zsh-completions linux linux-firmware networkmanager neovim
}

##############################################################################################
#  Update fstab file
###############################################################################################
Fstab_Setup() {
  # generate fstab
  echo "
      ????????????????????
      Update fstab
      ####################
  "
  genfstab -U /mnt >> /mnt/etc/fstab
}

##############################################################################################
#  Install next script for install
###############################################################################################
Install_Script() {
  echo "
    ????????????????????
    Install next script
    ####################
  "
  local setupurl="$1"; shift
  curl --url $setupurl >> /mnt/shell.sh 
}

##############################################################################################
#  Next step chroot
###############################################################################################
Chroot() {
  echo "
    ????????????????????
    Boot into chroot
    ####################
  "
  arch-chroot /mnt /bin/zsh
}

##############################################################################################
#  Install process
###############################################################################################


Setup_Font
Update_Mirrors
Sync_Time
Encrypt_Drive "ROOTDRIVE" "DRIVE_PASSPHRASE"
Open_Root_Container "ROOTDRIVE" "DRIVE_PASSPHRASE"
Format_Boot "BOOTDRIVE"
Format_Root
Create_BTRFS_Volumes
Create_Swapfile
Boot_Mount
Installation
Fstab_Setup
Install_Script
Chroot

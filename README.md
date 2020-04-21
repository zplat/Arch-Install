# Arch-Install

I am a newbie to programming and linux. This script was designed to make my install as painless as possible. 

This install script has been written specifically for my own Arch Linux install. It is very basic and limited. The root, swap and home partitions reside on LVM logical volumes, which are on a single LUKS (encrypted) partition on a GPT-formatted partition on the hard drive. For me this is 30 Gb. I boot off a removable usb stick. I have windows 10 installed on the drive. 

The followinge web pages gave me enough insight and know-how to enable me to write this small script. No doubt there are loads more out there. 

Majority of this script is based on this web page
https://fogelholk.io/installing-arch-with-lvm-on-luks-and-btrfs/

Enabled me to write the script 
https://github.com/lukesmithxyz/larb

Though I installed Arch, I found this gentoo install tutorial very helpful.
https://wiki.gentoo.org/wiki/Sakaki%27s_EFI_Install_Guide

For security and hardening Arch
https://www.reddit.com/r/archlinux/comments/7np36m/detached_luks_header_full_disk_encryption_with/

Helpful YouTube sites (Just some of the many good ones out there). 
Linux centric
Luke Smith https://www.youtube.com/channel/UC2eYFnH61tmytImy1mTYvhA
DistroTube https://www.youtube.com/channel/UCVls1GmFKf6WlTraIb_IaJg
Brodie Robertson https://www.youtube.com/user/OmegaDungeon
gotbletu https://www.youtube.com/channel/UCkf4VIqu3Acnfzuk3kRIFwA

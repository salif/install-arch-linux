#!/usr/bin/sh

# Load Colemak keyboard layout
loadkeys colemak

# Connect to Wi-Fi
iwctl --passphrase passphrase station device connect SSID

timedatectl set-ntp true

cfdisk
fdisk -l

# Device     Size Type
# /dev/sdb1  256M EFI System
# /dev/sdb2    8G Linux swap
# /dev/sdb3   64G Linux filesystem
# /dev/sdb4  150G Linux filesystem

mkfs.fat -F32 -n BOOT /dev/sdb1
mkswap -L SWAP /dev/sdb2
mkfs.ext4 -L ROOT -F /dev/sdb3
mkfs.ext4 -L HOME -F /dev/sdb4

swapon /dev/sdb2
mount /dev/sdb3 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sdb1 /mnt/boot/efi
mkdir -p /mnt/home
mount /dev/sdb4 /mnt/home

lsblk

# sdb      232,9G  disk 
# ├─sdb1     256M  part /boot/efi
# ├─sdb2       8G  part [SWAP]
# ├─sdb3      64G  part /
# └─sdb4     150G  part /home

pacstrap /mnt base base-devel linux linux-firmware vim networkmanager
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

vim /etc/locale.gen
locale-gen
echo 'LANG="en_US.UTF-8"' >> /etc/locale.conf
echo 'LC_ADDRESS="bg_BG.UTF-8"' >> /etc/locale.conf
echo 'LC_IDENTIFICATION="bg_BG.UTF-8"' >> /etc/locale.conf
echo 'LC_MEASUREMENT="bg_BG.UTF-8"' >> /etc/locale.conf
echo 'LC_MONETARY="bg_BG.UTF-8"' >> /etc/locale.conf
echo 'LC_NAME="bg_BG.UTF-8"' >> /etc/locale.conf
echo 'LC_NUMERIC="bg_BG.UTF-8"' >> /etc/locale.conf
echo 'LC_PAPER="bg_BG.UTF-8"' >> /etc/locale.conf
echo 'LC_TELEPHONE="bg_BG.UTF-8"' >> /etc/locale.conf
echo 'LC_TIME="bg_BG.UTF-8"' >> /etc/locale.conf

ln -sf /usr/share/zoneinfo/Europe/Sofia /etc/localtime
hwclock --systohc
echo "KEYMAP=colemak" > /etc/vconsole.conf
echo "archlinux" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.0.1 archlinux.localdomain archlinux" >> /etc/hosts

mkinitcpio -P

passwd
useradd -m -g users -G wheel,storage,power salifm
passwd salifm
chfn salifm

pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=archlinux
grub-mkconfig -o /boot/grub/grub.cfg
pacman -S intel-ucode
grub-mkconfig -o /boot/grub/grub.cfg

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector --protocol http --latest 70 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syyu
pacman -S sudo
EDITOR=vim visudo # Uncomment %wheel ALL=(ALL) ALL

pacman -S xorg xorg-apps xorg-fonts xorg-drivers mesa lightdm lightdm-webkit2-greeter gnome-terminal cinnamon
vim /etc/lightdm/lightdm.conf # Add greeter-session=lightdm-webkit2-greeter
exit
reboot

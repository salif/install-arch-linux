#!/usr/bin/bash

read -p "disk: " disk
cfdisk "$disk"
mkfs.fat -F32 -n BOOT "$disk"1
cryptsetup --label SYSTEM --pbkdf argon2id luksFormat "$disk"2
read -p "lvm name: " lvmname
cryptsetup luksOpen  "$disk"2 "$lvmname"
pvcreate /dev/mapper/"$lvmname"
read -p "lvm volume name: " lvmvolumename
vgcreate "$lvmvolumename" /dev/mapper/"$lvmname"
read -p "lvm swap name: " lvmswapname
read -p "swap size: " swapsize
lvcreate -L "$swapsize" "$lvmvolumename" -n "$lvmswapname"
read -p "lvm root name: " lvmrootname
read -p "root size: " rootsize
lvcreate -L "$rootsize" "$lvmvolumename" -n "$lvmrootname"
read -p "lvm home name: " lvmhomename
lvcreate -l +100%FREE "$lvmvolumename" -n "$lvmhomename"
mkswap -L SWAP /dev/"$lvmvolumename"/"$lvmswapname"
mkfs.xfs -L ROOT /dev/"$lvmvolumename"/"$lvmrootname"
mkfs.xfs -L HOME /dev/"$lvmvolumename"/"$lvmhomename"
swapon /dev/"$lvmvolumename"/"$lvmswapname"
mount /dev/"$lvmvolumename"/"$lvmrootname" /mnt
mount "$disk"1 /mnt/boot
mount /dev/"$lvmvolumename"/"$lvmhomename" /mnt/home
basestrap /mnt base base-devel openrc linux linux-firmware nano xfsprog
fstabgen -U /mnt >> /mnt/etc/fstab
artix-chroot /mnt
read -p "timezone(ex. Europe/London): " cttimezone
ln -sf /usr/share/zoneinfo/"$cttimezone" /etc/localtime
hwclock --systohc
read -p "now enable locales, press any key to continue" pnktc
nano /etc/locale.gen
locale-gen
read -p "LANG: " llang
export LANG="$llang"
export LC_COLLATE=C
echo LANG="$llang" >> /etc/locale.conf
echo LC_COLLATE=C >> /etc/locale.conf
cat /etc/locale.conf
read -p "now enter hostname, press any key to continue" pnktc
nano /etc/conf.d/hostname
read -p "now enter keymaps, press any key to continue" pnktc
nano /etc/conf.d/keymaps
read -p "now choose password for root, press any key to continue" pnktc 
passwd
tthostname=$(cat /etc/conf.d/hostname)
echo "127.0.0.1        localhost" >> /etc/hosts
echo "::1              localhost" >> /etc/hosts
echo "127.0.1.1        $tthostname.localdomain	$tthostname" >> /etc/hosts
cat /etc/hosts
read -p "now add 'encrypt', it should be like this: 'base udev autodetect modconf block encrypt keyboard keymap lvm2 filesystems fsck', press any key to continue" pnktc
nano /etc/mkinitcpio.conf
pacman -Syyu
pacman -S dhcpcd lvm2 cryptsetup linux mkinitcpio --needed
mkinitcpio -p linux
pacman -S grub os-prober efibootmgr
read -p "disk: " disk
gruu=$(blkid -s UUID -o value "$disk"2)
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=$gruu:$lvmvolumename loglevel=3 quiet net.ifnames=0\"" >> /etc/default/grub
nano /etc/default/grub
nano /etc/fstab
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
pacman -S gptfdisk freetype2 iw wpa_supplicant device-mapper-openrc lvm2-openrc cryptsetup-openrc xfsdump cronie cronie-openrc ntp ntp-openrc acpid acpid-openrc syslog-ng syslog-ng-openrc networkmanager networkmanager-openrc networkmanager-openvpn network-manager-applet bash-completion net-tools --needed
rc-update add device-mapper boot
rc-update add lvm boot
rc-update add dmcrypt boot
rc-update add dbus defaul
rc-update add cronie default
rc-update add elogind boot
rc-update add ntpd default
rc-update add acpid default
rc-update add syslog-ng default
rc-update add NetworkManager default
echo "done"

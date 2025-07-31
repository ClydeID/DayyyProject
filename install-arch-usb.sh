#!/bin/bash

# === CONFIGURABLE VARIABLES ===
DISK="/dev/sda1"         # Ganti sesuai device USB kamu
HOSTNAME="DayyyProject"
USERNAME="Dayyy"
PASSWORD="KalemKalem"

# === WARNING ===
echo "WARNING: This will erase all data on $DISK"
echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
sleep 5

# === PARTITION & FORMAT ===
parted --script $DISK mklabel gpt
parted --script $DISK mkpart ESP fat32 1MiB 513MiB
parted --script $DISK set 1 esp on
parted --script $DISK mkpart primary ext4 513MiB 100%

mkfs.fat -F32 ${DISK}1
mkfs.ext4 -F ${DISK}2

# === MOUNT ===
mount ${DISK}2 /mnt
mkdir -p /mnt/boot/efi
mount ${DISK}1 /mnt/boot/efi

# === INSTALL BASE SYSTEM ===
pacstrap /mnt base linux linux-firmware

# === FSTAB ===
genfstab -U /mnt >> /mnt/etc/fstab

# === CHROOT CONFIGURATION ===
arch-chroot /mnt /bin/bash <<EOF

# Timezone & Locale
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen

cat <<LOCALE > /etc/locale.conf
LANG=en_US.UTF-8
LOCALE

# Hostname & Hosts
echo "$HOSTNAME" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
HOSTS

# Root password
echo "root:$PASSWORD" | chpasswd

# User setup
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Bootloader
pacman --noconfirm -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# GUI & Essentials
pacman --noconfirm -S xorg xorg-xinit hyprland kitty networkmanager
systemctl enable NetworkManager

# Create xinitrc for Hyprland
echo "exec Hyprland" > /home/$USERNAME/.xinitrc
chown $USERNAME:$USERNAME /home/$USERNAME/.xinitrc

EOF

# === DONE ===
echo "Installation complete. You can reboot now."
echo "After reboot, login manually as $USERNAME, then run 'startx' to enter Hyprland."

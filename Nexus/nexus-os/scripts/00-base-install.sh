#!/bin/bash
# ============================================================
#  NEXUS OS — Base Install Script
#  Run this from a live Arch ISO to bootstrap the base system
#  Usage: curl -sL <url> | bash  OR  bash 00-base-install.sh
# ============================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${CYAN}[NEXUS]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
die()  { echo -e "${RED}[ERR]${NC} $1"; exit 1; }

# ── CONFIG ───────────────────────────────────────────────────
HOSTNAME="nexus"
USERNAME="dominic"
TIMEZONE="Pacific/Honolulu"
LOCALE="en_US.UTF-8"
KEYMAP="us"
DISK=""          # Set this! e.g. /dev/sda or /dev/nvme0n1
ENCRYPT=true     # LUKS2 full disk encryption

# ── DETECT DISK ──────────────────────────────────────────────
detect_disk() {
  log "Available disks:"
  lsblk -d -o NAME,SIZE,MODEL | grep -v loop
  echo ""
  read -rp "  Enter target disk (e.g. sda or nvme0n1): " DISK_INPUT
  DISK="/dev/$DISK_INPUT"
  [[ -b "$DISK" ]] || die "Disk $DISK not found"
  warn "ALL DATA ON $DISK WILL BE DESTROYED. Continue? (yes/no)"
  read -r CONFIRM
  [[ "$CONFIRM" == "yes" ]] || die "Aborted."
}

# ── PARTITION ────────────────────────────────────────────────
partition_disk() {
  log "Partitioning $DISK..."
  # GPT: 1GB EFI + rest for LUKS
  parted -s "$DISK" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 1025MiB \
    set 1 esp on \
    mkpart primary 1025MiB 100%

  # Identify partitions
  if [[ "$DISK" == *nvme* ]]; then
    EFI="${DISK}p1"
    ROOT="${DISK}p2"
  else
    EFI="${DISK}1"
    ROOT="${DISK}2"
  fi
  ok "Partitioned: EFI=$EFI  ROOT=$ROOT"
}

# ── ENCRYPTION ───────────────────────────────────────────────
setup_encryption() {
  if [[ "$ENCRYPT" == true ]]; then
    log "Setting up LUKS2 encryption on $ROOT..."
    warn "Enter your disk encryption passphrase (remember this!):"
    cryptsetup luksFormat --type luks2 "$ROOT"
    cryptsetup open "$ROOT" cryptroot
    ROOT_MOUNT="/dev/mapper/cryptroot"
    ok "Encryption set up"
  else
    ROOT_MOUNT="$ROOT"
  fi
}

# ── FORMAT ───────────────────────────────────────────────────
format_partitions() {
  log "Formatting partitions..."
  mkfs.fat -F32 "$EFI"
  mkfs.btrfs -f -L "nexus-root" "$ROOT_MOUNT"

  # Btrfs subvolumes for easy snapshots
  mount "$ROOT_MOUNT" /mnt
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  btrfs subvolume create /mnt/@snapshots
  btrfs subvolume create /mnt/@var_log
  umount /mnt

  # Mount with options
  mount -o noatime,compress=zstd,subvol=@ "$ROOT_MOUNT" /mnt
  mkdir -p /mnt/{home,.snapshots,var/log,boot/efi}
  mount -o noatime,compress=zstd,subvol=@home       "$ROOT_MOUNT" /mnt/home
  mount -o noatime,compress=zstd,subvol=@snapshots  "$ROOT_MOUNT" /mnt/.snapshots
  mount -o noatime,compress=zstd,subvol=@var_log    "$ROOT_MOUNT" /mnt/var/log
  mount "$EFI" /mnt/boot/efi
  ok "Partitions formatted and mounted (btrfs + zstd compression)"
}

# ── PACSTRAP ─────────────────────────────────────────────────
install_base() {
  log "Installing base system (this takes a few minutes)..."

  pacstrap /mnt \
    base base-devel linux linux-firmware linux-headers \
    btrfs-progs \
    networkmanager \
    grub efibootmgr \
    sudo git curl wget \
    zsh neovim \
    man-db man-pages \
    reflector \
    cryptsetup \
    pipewire pipewire-pulse pipewire-alsa wireplumber \
    bluez bluez-utils

  ok "Base system installed"
}

# ── FSTAB ────────────────────────────────────────────────────
generate_fstab() {
  log "Generating fstab..."
  genfstab -U /mnt >> /mnt/etc/fstab
  ok "fstab generated"
}

# ── CHROOT CONFIG ────────────────────────────────────────────
configure_system() {
  log "Configuring system in chroot..."

  arch-chroot /mnt /bin/bash -e <<CHROOT
# Timezone
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

# Locale
echo "${LOCALE} UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# Hostname
echo "${HOSTNAME}" > /etc/hostname
cat >> /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

# mkinitcpio for LUKS
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# GRUB with LUKS
CRYPTUUID=\$(blkid -s UUID -o value ${ROOT})
sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=\${CRYPTUUID}:cryptroot root=/dev/mapper/cryptroot\"|" /etc/default/grub
sed -i 's/#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=NEXUS
grub-mkconfig -o /boot/grub/grub.cfg

# Create user
useradd -m -G wheel,audio,video,storage,optical,network -s /bin/zsh ${USERNAME}
echo "Set password for ${USERNAME}:"
passwd ${USERNAME}

# Sudo
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Enable services
systemctl enable NetworkManager
systemctl enable bluetooth

CHROOT

  ok "System configured"
}

# ── MAIN ─────────────────────────────────────────────────────
main() {
  clear
  echo -e "${CYAN}"
  cat << 'EOF'
  ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗     ██████╗ ███████╗
  ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝    ██╔═══██╗██╔════╝
  ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗    ██║   ██║███████╗
  ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║    ██║   ██║╚════██║
  ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║    ╚██████╔╝███████║
  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝     ╚═════╝ ╚══════╝
EOF
  echo -e "${NC}"
  log "NEXUS OS Base Installer — Arch Linux Foundation"
  echo ""

  detect_disk
  partition_disk
  setup_encryption
  format_partitions
  install_base
  generate_fstab
  configure_system

  echo ""
  ok "═══════════════════════════════════════════════"
  ok "  Base install complete! Next steps:"
  ok "  1. Run 01-desktop.sh after first boot"
  ok "  2. Run 02-cybersec.sh for security tools"
  ok "  3. Run 03-theme.sh for NEXUS aesthetic"
  ok "═══════════════════════════════════════════════"
  warn "You can now reboot into your new system."
}

main

#!/usr/bin/env bash
# Privacy NixOS Installer - One-command install from GitHub
set -euo pipefail

# ============================================================================
# CONFIGURATION - Edit these if needed
# ============================================================================

GITHUB_USER="not-a-longneck"
GITHUB_REPO="privacy-nixos"
BOOT_DISK="/dev/vda"
NIX_DISK="/dev/vdb"

# ============================================================================
# Root check
# ============================================================================

if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root. Restarting with sudo..."
    exec sudo bash "$0" "$@"
fi

echo "============================================"
echo "Privacy-Focused NixOS Installer"
echo "============================================"
echo ""
echo "Repository: https://github.com/$GITHUB_USER/$GITHUB_REPO"
echo "Boot disk: $BOOT_DISK"
echo "Nix disk:  $NIX_DISK"
echo ""
echo "WARNING: This will ERASE all data on these disks!"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

# ============================================================================
# Format Disks
# ============================================================================

echo ""
echo "Formatting disks..."

# Boot partition (vda)
wipefs -a "$BOOT_DISK"
parted "$BOOT_DISK" --script mklabel gpt
parted "$BOOT_DISK" --script mkpart ESP fat32 1MiB 100%
parted "$BOOT_DISK" --script set 1 boot on
mkfs.vfat -F32 -n BOOT "${BOOT_DISK}1"

# Nix partition (vdb)
wipefs -a "$NIX_DISK"
parted "$NIX_DISK" --script mklabel gpt
parted "$NIX_DISK" --script mkpart primary ext4 1MiB 100%
mkfs.ext4 -L NIX "${NIX_DISK}1"

echo "✓ Disks formatted"

# ============================================================================
# Mount Filesystems
# ============================================================================

echo ""
echo "Mounting filesystems..."

mount -t tmpfs none /mnt
mkdir -p /mnt/{boot,nix,etc/nixos}
mount "${BOOT_DISK}1" /mnt/boot
mount "${NIX_DISK}1" /mnt/nix
mkdir -p /mnt/nix/persist/etc/nixos
mount --bind /mnt/nix/persist/etc/nixos /mnt/etc/nixos

echo "✓ Filesystems mounted"

# ============================================================================
# Generate Hardware Configuration
# ============================================================================

echo ""
echo "Generating hardware configuration..."
nixos-generate-config --root /mnt
echo "✓ Hardware config generated"

# ============================================================================
# Fetch Configuration from GitHub
# ============================================================================

echo ""
echo "Fetching configuration from GitHub..."

cd /mnt/etc/nixos

# Download config files
for file in flake.nix configuration.nix home.nix; do
    echo "  Downloading $file..."
    curl -fsSL "https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/main/$file" -o "$file"
done

echo "✓ Configuration fetched"

# ============================================================================
# Set Password
# ============================================================================

echo ""
echo "Setting up user password..."
echo "Enter password for user 'user':"
HASHED_PASSWORD=$(mkpasswd -m sha-512)

# Update configuration.nix with the hashed password
sed -i "s|hashedPassword = \".*\";|hashedPassword = \"$HASHED_PASSWORD\";|" /mnt/etc/nixos/configuration.nix

echo "✓ Password set"

# ============================================================================
# Install NixOS
# ============================================================================

echo ""
echo "Installing NixOS..."
echo "This may take a while..."

nixos-install --flake /mnt/etc/nixos#privacy-vm

echo ""
echo "============================================"
echo "✓ Installation complete!"
echo "============================================"
echo ""
echo "Your privacy-focused NixOS is ready!"
echo ""
echo "Features enabled:"
echo "  • Root on tmpfs (wiped every boot)"
echo "  • No system logs"
echo "  • No shell history"
echo "  • No crash dumps"
echo "  • No thumbnails"
echo ""
echo "What persists:"
echo "  • /nix/store (packages)"
echo "  • /etc/nixos (config)"
echo ""
echo "Everything else is wiped on reboot!"
echo ""
read -p "Press Enter to reboot now, or Ctrl+C to stay in installer..."
reboot

#!/usr/bin/env bash
# Privacy NixOS Installer - GitHub version
# This version downloads config from your GitHub repo
set -euo pipefail

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root. Restarting with sudo..."
    exec sudo bash "$0" "$@"
fi

# ============================================================================
# CONFIGURATION - Edit these if needed
# ============================================================================

GITHUB_USER="${1:-YOUR_USERNAME}"  # Pass as first argument or edit here
GITHUB_REPO="${2:-privacy-nixos}"  # Pass as second argument or edit here
BOOT_DISK="/dev/vda"
NIX_DISK="/dev/vdb"

echo "============================================"
echo "Privacy-Focused NixOS Installer (GitHub)"
echo "============================================"
echo ""
echo "Fetching from: https://github.com/$GITHUB_USER/$GITHUB_REPO"
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

# Boot partition
wipefs -a "$BOOT_DISK"
parted "$BOOT_DISK" --script mklabel gpt
parted "$BOOT_DISK" --script mkpart ESP fat32 1MiB 100%
parted "$BOOT_DISK" --script set 1 boot on
mkfs.vfat -F32 -n BOOT "${BOOT_DISK}1"

# Nix partition
wipefs -a "$NIX_DISK"
parted "$NIX_DISK" --script mklabel gpt
parted "$NIX_DISK" --script mkpart primary ext4 1MiB 100%
mkfs.ext4 -L NIX "${NIX_DISK}1"

echo "✓ Disks formatted"

# ============================================================================
# Mount File Systems
# ============================================================================

echo ""
echo "Mounting file systems..."

# Create tmpfs root (the "privacy" magic)
mount -t tmpfs -o mode=755 none /mnt

# Mount persistent nix partition
mkdir -p /mnt/nix
mount "${NIX_DISK}1" /mnt/nix

# Setup persistent config directory
mkdir -p /mnt/nix/persist/etc/nixos
mkdir -p /mnt/etc/nixos

# Bind mount the config directory so it persists
mount --bind /mnt/nix/persist/etc/nixos /mnt/etc/nixos

# Mount boot partition
mkdir -p /mnt/boot
mount "${BOOT_DISK}1" /mnt/boot

echo "✓ File systems mounted"

# ============================================================================
# Generate Hardware Configuration
# ============================================================================

echo ""
echo "Generating hardware configuration..."

# Generate the base config
nixos-generate-config --root /mnt

# Since we use a custom disk layout (tmpfs root), we keep the generated 
# hardware-configuration.nix but we will use your custom flake/configuration
echo "✓ Hardware config generated"

# ============================================================================
# Fetch Configuration from GitHub
# ============================================================================

echo ""
echo "Fetching configuration from GitHub..."
cd /mnt/etc/nixos

# Download files from GitHub
for file in flake.nix configuration.nix home.nix README.md; do
    echo "Downloading $file..."
    curl -L "https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/main/$file" -o "$file"
done

echo "✓ Configuration fetched from GitHub"

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

# We run the install pointing to the flake in /mnt/etc/nixos
nixos-install --flake /mnt/etc/nixos#privacy-vm

echo ""
echo "============================================"
echo "✓ Installation complete!"
echo "============================================"
echo ""
echo "Configuration downloaded from:"
echo "  https://github.com/$GITHUB_USER/$GITHUB_REPO"
echo ""
echo "Next steps:"
echo "1. Reboot: reboot"
echo "2. Remove live USB"
echo "3. Your system will boot fresh every time"
echo ""
read -p "Press Enter to reboot now, or Ctrl+C to stay in installer..."
reboot

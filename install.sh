#!/usr/bin/env bash
# Privacy NixOS Installer - Run from NixOS live USB
set -euo pipefail

GITHUB_REPO="YOUR_USERNAME/privacy-nixos"  # Change this to your GitHub repo
BOOT_DISK="/dev/vdb"  # 512MB disk for boot
NIX_DISK="/dev/vdc"   # 20-30GB disk for nix store

echo "============================================"
echo "Privacy-Focused NixOS Installer"
echo "============================================"
echo ""
echo "This will install NixOS with:"
echo "  - Root on tmpfs (wiped every boot)"
echo "  - No logs, history, or cache saved"
echo "  - Only /nix and config persist"
echo ""
echo "Boot disk: $BOOT_DISK"
echo "Nix disk:  $NIX_DISK"
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
# Mount Filesystems
# ============================================================================

echo ""
echo "Mounting filesystems..."

# Mount tmpfs root
mount -t tmpfs none /mnt

# Create mount points
mkdir -p /mnt/{boot,nix,etc/nixos}

# Mount boot
mount "${BOOT_DISK}1" /mnt/boot

# Mount nix store
mount "${NIX_DISK}1" /mnt/nix

# Create persistence directory
mkdir -p /mnt/nix/persist/etc/nixos

# Bind mount for /etc/nixos
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

# Clone your config repo
# Option 1: Use your GitHub repo
# git clone "https://github.com/$GITHUB_REPO.git" .

# Option 2: For now, download the example config
# You'll replace this with your repo later
cat > flake.nix << 'EOF'
{
  description = "Privacy-focused NixOS with ephemeral root";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.privacy-vm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.user = import ./home.nix;
        }
      ];
    };
  };
}
EOF

# Copy configuration.nix (keep the generated hardware-configuration.nix)
# This will be replaced by files from your repo

echo "✓ Configuration fetched"

# ============================================================================
# Set Password
# ============================================================================

echo ""
echo "Setting up user password..."
echo "Enter password for user 'user':"
HASHED_PASSWORD=$(mkpasswd -m sha-512)

# Update configuration.nix with the hashed password
# Note: In real usage, you'd have this in your GitHub repo
# For now, we'll inject it
sed -i "s|hashedPassword = \".*\"|hashedPassword = \"$HASHED_PASSWORD\"|" /mnt/etc/nixos/configuration.nix

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
echo "Next steps:"
echo "1. Reboot: reboot"
echo "2. Remove live USB"
echo "3. Your system will boot fresh every time"
echo ""
echo "Remember:"
echo "  - Everything except /nix and /etc/nixos is wiped on reboot"
echo "  - No logs, history, or cache is saved"
echo "  - Save important files before rebooting"
echo ""
read -p "Press Enter to reboot now, or Ctrl+C to stay in installer..."
reboot

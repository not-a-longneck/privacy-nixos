# Privacy NixOS - Quick Setup Guide

## VM Disk Setup (Before Installation)

Create these virtual disks in your VM manager:

1. **Boot disk**: 512 MB (virtio)
2. **Nix store disk**: 20-30 GB (virtio)

Example in virt-manager:
```
Disk 1: /dev/vdb - 512M  (EFI boot)
Disk 2: /dev/vdc - 20G   (Nix store + config)
```

## Installation (Two Options)

### Option A: From GitHub (Recommended for reuse)

1. **Push config to GitHub:**
   ```bash
   # On your local machine
   cd privacy-nixos
   git init
   git add flake.nix configuration.nix home.nix
   git commit -m "Initial privacy config"
   git remote add origin https://github.com/YOUR_USERNAME/privacy-nixos.git
   git push -u origin main
   ```

2. **Boot NixOS live USB in VM**

3. **Run installer:**
   ```bash
   curl -L https://raw.githubusercontent.com/YOUR_USERNAME/privacy-nixos/main/install.sh | bash
   ```

4. **Done!** Reboot and you have a privacy-focused NixOS.

### Option B: Manual Installation (For testing)

1. **Boot NixOS live USB**

2. **Format disks:**
   ```bash
   # Boot disk
   parted /dev/vdb --script mklabel gpt
   parted /dev/vdb --script mkpart ESP fat32 1MiB 100%
   parted /dev/vdb --script set 1 boot on
   mkfs.vfat -F32 -n BOOT /dev/vdb1

   # Nix disk
   parted /dev/vdc --script mklabel gpt
   parted /dev/vdc --script mkpart primary ext4 1MiB 100%
   mkfs.ext4 -L NIX /dev/vdc1
   ```

3. **Mount filesystems:**
   ```bash
   mount -t tmpfs none /mnt
   mkdir -p /mnt/{boot,nix,etc/nixos}
   mount /dev/vdb1 /mnt/boot
   mount /dev/vdc1 /mnt/nix
   mkdir -p /mnt/nix/persist/etc/nixos
   mount --bind /mnt/nix/persist/etc/nixos /mnt/etc/nixos
   ```

4. **Generate hardware config:**
   ```bash
   nixos-generate-config --root /mnt
   ```

5. **Copy config files to /mnt/etc/nixos:**
   ```bash
   # Copy flake.nix, configuration.nix, home.nix
   ```

6. **Set password:**
   ```bash
   # Generate hash
   mkpasswd -m sha-512
   
   # Edit configuration.nix and replace CHANGEME with your hash
   nano /mnt/etc/nixos/configuration.nix
   ```

7. **Install:**
   ```bash
   nixos-install --flake /mnt/etc/nixos#privacy-vm
   ```

8. **Reboot**

## What Gets Wiped vs What Persists

### ✅ PERSISTS (survives reboot):
- `/nix/store` - All your packages
- `/etc/nixos` - Your NixOS configuration files
- That's it!

### ❌ WIPED (every reboot):
- `/home/user/*` - Downloads, documents, everything
- All shell history
- All logs
- All thumbnails
- All cache
- Everything else!

## Daily Usage

### Making Config Changes
```bash
# Edit your config
sudo nano /etc/nixos/configuration.nix

# Rebuild
sudo nixos-rebuild switch --flake /etc/nixos#privacy-vm
```

### Saving Files Before Reboot
Remember: Everything in your home directory is wiped on reboot!

Options:
1. Copy to external USB
2. Push to Git remote
3. Upload to cloud storage
4. Use network share

### Adding Packages
```bash
# Edit configuration.nix
sudo nano /etc/nixos/configuration.nix

# Add to environment.systemPackages, example:
# environment.systemPackages = with pkgs; [
#   git
#   firefox
#   your-package-here
# ];

# Rebuild
sudo nixos-rebuild switch --flake /etc/nixos#privacy-vm
```

## Verification

After installation, verify your setup:

```bash
# Root should be tmpfs
df -h /
# Output: tmpfs ... /

# No logs should exist
ls /var/log
# Should be empty

# History disabled
echo $HISTFILE
# Output: /dev/null

# Persistent config
ls /etc/nixos
# Should show your config files
```

## Updating the System

```bash
# Update flake inputs
cd /etc/nixos
sudo nix flake update

# Rebuild with new packages
sudo nixos-rebuild switch --flake /etc/nixos#privacy-vm
```

## Troubleshooting

**System won't boot:**
- Check disk labels match: `BOOT` and `NIX`
- Verify mount points in hardware-configuration.nix

**Out of RAM:**
- Reduce tmpfs size in configuration.nix (change `size=4G`)
- Close unused applications

**Need to persist something:**
Edit configuration.nix and add bind mounts:
```nix
fileSystems."/home/user/projects" = {
  device = "/nix/persist/home/user/projects";
  options = [ "bind" ];
  depends = [ "/nix" ];
};
```

## File Structure

```
/
├── (tmpfs root - wiped on boot)
├── boot/           → /dev/vdb1 (EFI)
├── nix/            → /dev/vdc1 (persistent)
│   ├── store/      → Packages
│   └── persist/    → Your persistent data
│       └── etc/
│           └── nixos/  → Config files
└── etc/
    └── nixos/      → Bind mount to /nix/persist/etc/nixos
```

## Next Steps

1. **Add your SSH keys** (optional):
   ```nix
   # In configuration.nix
   fileSystems."/home/user/.ssh" = {
     device = "/nix/persist/home/user/.ssh";
     options = [ "bind" ];
   };
   ```

2. **Install a browser** (when ready):
   ```nix
   environment.systemPackages = with pkgs; [
     firefox
   ];
   ```

3. **Push config to GitHub** so you can reinstall easily

4. **Create VM template** for quick deployment

## Benefits of This Setup

✅ Fresh start every boot
✅ No forensic traces left behind  
✅ Simple to understand and maintain
✅ Easy to reinstall (just run script)
✅ Declarative - your whole system is in Git
✅ Resource efficient (6 cores, 8GB RAM is plenty)

## Important Notes

- This protects against data persistence, NOT live monitoring
- Use VPN/Tor for network privacy
- VM snapshots can still capture RAM
- Hypervisor can still see everything

**Remember:** Every reboot is a clean slate. Save your work!

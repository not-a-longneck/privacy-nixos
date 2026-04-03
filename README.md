# Privacy-Focused NixOS Configuration

Ephemeral NixOS setup with tmpfs root - everything wiped on reboot except your config.

## Quick Start

### VM Setup
Create two virtio disks:
- 512 MB for boot
- 20-30 GB for Nix store

### One-Command Install
```bash
curl -L https://raw.githubusercontent.com/YOUR_USERNAME/privacy-nixos/main/install.sh | bash
```

## Features

- ✅ Root filesystem on tmpfs (wiped every boot)
- ✅ No system logs saved
- ✅ No shell history
- ✅ No thumbnails or cache
- ✅ No crash dumps
- ✅ Only `/nix` and `/etc/nixos` persist
- ✅ Flakes + Home Manager
- ✅ Minimal and easy to understand

## What Persists

Only two things survive a reboot:
1. `/nix/store` - Your installed packages
2. `/etc/nixos` - This configuration

Everything else (home directory, logs, cache) is wiped clean.

## Customization

Edit `configuration.nix` to add packages:
```nix
environment.systemPackages = with pkgs; [
  firefox
  your-package
];
```

Rebuild:
```bash
sudo nixos-rebuild switch --flake /etc/nixos#privacy-vm
```

## Documentation

See [SETUP-GUIDE.md](SETUP-GUIDE.md) for detailed instructions.

## Use Cases

- Privacy-focused browsing
- Testing and development
- Sandboxed environment
- Clean slate for each session

## Warning

⚠️ Everything in your home directory is wiped on reboot. Save your work externally!

## License

MIT

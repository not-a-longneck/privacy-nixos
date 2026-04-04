{ config, pkgs, ... }:

let
  nix-save = pkgs.writeShellScriptBin "nix-save" ''
    CONFIG_DIR="/etc/nixos"
    cd $CONFIG_DIR

    # 1. Protect the hardware file from the git reset
    cp hardware-configuration.nix /tmp/hw-bak.nix
    
    # 2. Sync with GitHub
    sudo git fetch origin main
    sudo git reset --hard origin/main

    # 3. Restore the hardware file
    cp /tmp/hw-bak.nix hardware-configuration.nix
    sudo git add hardware-configuration.nix

    # 4. Rebuild the system
    sudo nix flake update
    sudo nixos-rebuild switch --flake .#privacy-vm
  '';

in
{
  environment.systemPackages = [ nix-save ];
}

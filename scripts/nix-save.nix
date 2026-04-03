{ config, pkgs, ... }:

let
  nix-save = pkgs.writeShellScriptBin "nix-save" ''
    echo "Fetching latest configs from GitHub..."
    cd /etc/nixos
    
    # Pull the entire repository (grabs all new folders and scripts instantly!)
    sudo git pull origin main
    
    # Stage any local changes (like hardware-configuration.nix)
    sudo git add .
    
    echo "Rebuilding NixOS..."
    sudo nixos-rebuild switch --flake /etc/nixos#privacy-vm
    echo "Update complete! 🎉"
  '';
in
{
  environment.systemPackages = [ nix-save ];
}

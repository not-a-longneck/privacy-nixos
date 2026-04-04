{ config, pkgs, ... }:

let
  nix-save = pkgs.writeShellScriptBin "nix-save" ''
    CONFIG_DIR="/etc/nixos"
    
    echo "1. Pulling latest changes from GitHub..."
    cd $CONFIG_DIR
    sudo git pull origin main --rebase
    sudo nix flake update
    sudo nixos-rebuild switch --flake "$CONFIG_DIR#privacy-vm"
  '';
in
{
  environment.systemPackages = [ nix-save ];
}

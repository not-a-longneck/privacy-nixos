{ config, pkgs, ... }:

let
  nix-save = pkgs.writeShellScriptBin "nix-save" ''
    CONFIG_DIR="/etc/nixos"
    cd $CONFIG_DIR

nix-save = pkgs.writeShellScriptBin "nix-save" ''
    cd /etc/nixos
    sudo git fetch origin main
    sudo git reset --hard origin/main
    sudo nix flake update
    sudo nixos-rebuild switch --flake .#your-hostname
  '';

in
{
  environment.systemPackages = [ nix-save ];
}

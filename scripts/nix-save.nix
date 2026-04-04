{ config, pkgs, ... }:

let
  nix-save = pkgs.writeShellScriptBin "nix-save" ''
    CONFIG_DIR="/etc/nixos"
    cd $CONFIG_DIR

    sudo git fetch origin main
    sudo git reset --hard origin/main
    sudo git add hardware-configuration.nix # ensure that hardware doesn't get deleted
    sudo nix flake update
    sudo nixos-rebuild switch --flake .#privacy-vm
  '';

in
{
  environment.systemPackages = [ nix-save ];
}

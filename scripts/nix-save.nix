{ config, pkgs, ... }:

let
  nix-save = pkgs.writeShellScriptBin "nix-save" ''
    CONFIG_DIR="/etc/nixos"
    
    echo "1. Pulling latest changes from GitHub..."
    cd $CONFIG_DIR
    sudo git pull origin main --rebase

    # This updates your lock file for new inputs like nix-flatpak!
    echo "2. Updating dependencies..."
    sudo nix flake update

    # echo "3. Staging changes..."
    # sudo git add .

    echo "4. Rebuilding the system..."
    if sudo nixos-rebuild switch --flake "$CONFIG_DIR#privacy-vm"; then
        
        gen_num=$(readlink /nix/var/nix/profiles/system | cut -d- -f2)
        
        # echo "5. Saving and Syncing to GitHub..."
        # sudo git commit -m "Gen $gen_num: Update via nix-save $(date +'%Y-%m-%d %H:%M')"
        # sudo git push origin main
        
        echo "Successfully updated to Generation $gen_num and pushed to GitHub! 🎉"
    else
        echo "❌ Rebuild failed! Changes were not committed."
        exit 1
    fi
  '';
in
{
  environment.systemPackages = [ nix-save ];
}

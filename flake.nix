{
  description = "Privacy-focused NixOS with ephemeral root";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.4.1";
    # ADD THIS LINE:
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, home-manager, nix-flatpak, impermanence, ... }: {
    nixosConfigurations.privacy-vm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix
        # ADD THIS LINE:
        impermanence.nixosModules.impermanence
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.user = {
            imports = [ 
              ./home.nix 
              nix-flatpak.homeManagerModules.nix-flatpak 
            ];
          };
        }
      ];
    };
  };
}

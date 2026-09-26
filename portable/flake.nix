{
  description = "Portable USB NixOS host";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote/v0.4.3";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.home-manager = {
    url = "github:nix-community/home-manager/release-25.11";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixvim = {
    url = "github:nix-community/nixvim/nixos-25.11";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, nixvim, lanzaboote, ... }: {
    nixosConfigurations.portable-usb = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        lanzaboote.nixosModules.lanzaboote
        ./hosts/usb.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.sharedModules = [ nixvim.homeModules.nixvim ];
          home-manager.users.zarred = import ./home/default.nix;
          # Add future desktop Home Manager imports in home/default.nix.
        }
      ];
    };
  };
}

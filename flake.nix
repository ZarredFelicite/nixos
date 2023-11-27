{
  description = "Zarred's NixOS flake";
  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nur = { url = "github:nix-community/NUR"; };
    home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
    stylix.url = "github:danth/stylix";
    impermanence.url = "github:nix-community/impermanence";
    sops-nix.url = "github:Mic92/sops-nix";

    hyprland = { url = "github:hyprwm/Hyprland";};
    hyprpaper = { url = "github:hyprwm/hyprpaper"; };#inputs.nixpkgs.follows = "nixpkgs"; };
    hy3 = { url = "github:outfoxxed/hy3"; };
    hyprgrass = { url = "github:horriblename/hyprgrass"; inputs.hyprland.follows = "hyprland"; };

    nixvim = { url = "github:nix-community/nixvim?rev=358f5732f2443a922a6ceee54b5740efabe0950c"; inputs.nixpkgs.follows = "nixpkgs"; };
    anyrun = { url = "github:Kirottu/anyrun"; inputs.nixpkgs.follows = "nixpkgs"; };
    waybar = { url = "github:Alexays/Waybar"; inputs.nixpkgs.follows = "nixpkgs"; };
    himalaya.url = "github:soywod/himalaya";
  };
  outputs = { self, nixpkgs, home-manager, nixos-hardware, ...  }@inputs:
    let
      lib = nixpkgs.lib // home-manager.lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = f: lib.genAttrs systems (sys: f nixpkgs.legacyPackages.${sys});
    in {
      inherit lib;
      #packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });

      # use updated wayland packages
      nixpkgs.overlays = [
        inputs.nixpkgs-wayland.overlay
        (import ./overlays)
        (self: super: {
          nixos-option = let
            flake-compact = super.fetchFromGitHub {
              owner = "edolstra";
              repo = "flake-compat";
              rev = "12c64ca55c1014cdc1b16ed5a804aa8576601ff2";
              sha256 = "sha256-hY8g6H2KFL8ownSiFeMOjwPC8P0ueXpCVEbxgda3pko=";
            };
            prefix = ''(import ${flake-compact} { src = /etc/nixos; }).defaultNix.nixosConfigurations.\$(hostname)'';
          in super.runCommandNoCC "nixos-option" { buildInputs = [ super.makeWrapper ]; } ''
            makeWrapper ${super.nixos-option}/bin/nixos-option $out/bin/nixos-option \
              --add-flags --config_expr \
              --add-flags "\"${prefix}.config\"" \
              --add-flags --options_expr \
              --add-flags "\"${prefix}.options\""
          '';
        })
      ];

      nixosConfigurations = {
        web = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs ; };
      	  modules = [
            inputs.stylix.nixosModules.stylix
            ./hosts/web.nix
            ./roles/desktop.nix
            ./sys/impermanence.nix
            ./sys/nfs.nix
            ./sys/syncthing.nix
          ];
        };
        nano = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs ; };
      	  modules = [
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-nano-gen1
            inputs.stylix.nixosModules.stylix
            ./hosts/nano.nix
            ./roles/desktop.nix
            ./sys/impermanence.nix
            ./sys/nfs.nix
            ./sys/syncthing.nix
          ];
        };
        surface = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit self inputs ; };
      	  modules = [
            nixos-hardware.nixosModules.microsoft-surface-common
            inputs.stylix.nixosModules.stylix
            ./hosts/surface.nix
            ./roles/desktop.nix
            ./sys/impermanence.nix
            ./sys/nfs.nix
            ./sys/syncthing.nix
          ];
        };
        sankara = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit self inputs ; };
      	  modules = [
            inputs.stylix.nixosModules.stylix
            ./hosts/sankara.nix
            ./roles/server.nix
            ./sys/impermanence.nix
            ./sys/syncthing.nix
          ];
        };
      };
    };
}

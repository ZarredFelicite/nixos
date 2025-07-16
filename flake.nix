{
  description = "Zarred's NixOS flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = { url = "github:nix-community/home-manager/release-25.05"; inputs.nixpkgs.follows = "nixpkgs"; };
    nur = { url = "github:nix-community/NUR"; };
    flake-utils.url = "github:numtide/flake-utils";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    impermanence.url = "github:nix-community/impermanence";
    stylix.url = "github:danth/stylix/release-25.05";
    sops-nix.url = "github:Mic92/sops-nix";

    #hyprland = { type = "git"; url = "https://github.com/hyprwm/Hyprland?rev=v0.47.0"; submodules = true;};
    rose-pine-hyprcursor = { url = "github:ndom91/rose-pine-hyprcursor"; };
    vigiland.url = "github:jappie3/vigiland";

    nix-vscode-extensions = { url = "github:nix-community/nix-vscode-extensions"; inputs.nixpkgs.follows = "nixpkgs-unstable"; };
    nixvim = { url = "github:nix-community/nixvim"; }; # nixvim needs it's own nixpkgs
    spicetify-nix = { url = "github:Gerg-L/spicetify-nix"; inputs.nixpkgs.follows = "nixpkgs"; };

    #claude-desktop = { url = "github:k3d3/claude-desktop-linux-flake"; inputs.nixpkgs.follows = "nixpkgs"; inputs.flake-utils.follows = "flake-utils"; };
  };
  outputs = {
    self, nixpkgs,
    nixpkgs-unstable,
    home-manager, nixos-hardware, ...  }@inputs:
    let
      lib = nixpkgs.lib // home-manager.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = [ inputs.nix-vscode-extensions.overlays.default ];
      };
    in {
      inherit lib;
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
          inherit system;
          specialArgs = {
            inherit inputs self;
            inherit pkgs-unstable;
            #inherit pkgs-stable;
          };
      	  modules = [
            ({ nixpkgs.overlays = [
              (import ./overlays/omniverse.nix )
            ]; })
            inputs.stylix.nixosModules.stylix
            ./hosts/web.nix
            ./roles/desktop.nix
          ];
        };
        nano = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs self;
            inherit pkgs-unstable;
            #inherit pkgs-stable;
          };
      	  modules = [
            ({ nixpkgs.overlays = [
              (import ./overlays/omniverse.nix )
            ]; })
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-nano-gen1
            inputs.stylix.nixosModules.stylix
            ./hosts/nano.nix
            ./roles/desktop.nix
          ];
        };
        sankara = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs self;
            inherit pkgs-unstable;
            #inherit pkgs-stable;
          };
      	  modules = [
            inputs.stylix.nixosModules.stylix
            ./hosts/sankara.nix
            ./roles/server.nix
          ];
        };
        nano_minimal = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs self;
          };
      	  modules = [
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-nano-gen1
            inputs.stylix.nixosModules.stylix
            ./hosts/nano_minimal.nix
            ./profiles/common.nix
          ];
        };
        liveIso = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit self inputs ; };
      	  modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            inputs.stylix.nixosModules.stylix
            ./roles/iso.nix
          ];
        };
      };
    };
}

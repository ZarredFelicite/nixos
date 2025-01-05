{
  description = "Zarred's NixOS flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
    nur = { url = "github:nix-community/NUR"; };
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    impermanence.url = "github:nix-community/impermanence";
    stylix.url = "github:danth/stylix";
    sops-nix.url = "github:Mic92/sops-nix";

    hyprland = { type = "git"; url = "https://github.com/hyprwm/Hyprland?rev=v0.46.2"; submodules = true;};
    # TODO: switch to latest version when available https://github.com/NixOS/nix/issues/11946
    hyprland-plugins = { url = "github:hyprwm/hyprland-plugins"; inputs.hyprland.follows = "hyprland"; };
    hyprpaper = { url = "github:hyprwm/hyprpaper"; };
    hyprlang = { url = "github:hyprwm/hyprlang"; };
    hyprlock = { url = "github:hyprwm/hyprlock"; };
    hyprpanel = { url = "github:Jas-SinghFSU/HyprPanel"; };
    #hy3 = { url = "github:outfoxxed/hy3?ref=hl0.38.0"; inputs.hyprland.follows = "hyprland"; };
    hyprgrass = { url = "github:horriblename/hyprgrass"; inputs.hyprland.follows = "hyprland"; };
    hyprfocus = { url = "github:pyt0xic/hyprfocus"; inputs.hyprland.follows = "hyprland"; };
    rose-pine-hyprcursor = { url = "github:ndom91/rose-pine-hyprcursor"; };

    nixvim = { url = "github:nix-community/nixvim"; inputs.nixpkgs.follows = "nixpkgs"; };
    #ianyrun = { url = "github:Kirottu/anyrun"; inputs.nixpkgs.follows = "nixpkgs"; };
    #waybar = { url = "github:Alexays/Waybar"; inputs.nixpkgs.follows = "nixpkgs"; };
    himalaya.url = "github:soywod/himalaya";
    qrrs.url = "github:Lenivaya/qrrs";
    textfox.url = "github:adriankarlen/textfox";
    spicetify-nix = { url = "github:Gerg-L/spicetify-nix"; inputs.nixpkgs.follows = "nixpkgs"; };
  };
  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixos-hardware, ...  }@inputs:
    let
      lib = nixpkgs.lib // home-manager.lib;
      system = "x86_64-linux";
      #systems = [ "x86_64-linux" "aarch64-linux" ];
      #forEachSystem = f: lib.genAttrs systems (sys: f nixpkgs.legacyPackages.${sys});
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
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
            inherit inputs;
            inherit pkgs-unstable;
          };
      	  modules = [
            ({ nixpkgs.overlays = [
              (import ./overlays/omniverse.nix )
              inputs.hyprpanel.overlay
            ]; })
            inputs.stylix.nixosModules.stylix
            inputs.chaotic.nixosModules.default
            ./hosts/web.nix
            ./roles/desktop.nix
            ./sys/impermanence.nix
            ./sys/backups.nix
            ./sys/nfs.nix
            ./sys/syncthing.nix
            ./profiles/fans/fans.nix
          ];
        };
        nano = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit pkgs-unstable;
          };
      	  modules = [
            ({ nixpkgs.overlays = [
              (import ./overlays/omniverse.nix )
              inputs.hyprpanel.overlay
            ]; })
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-nano-gen1
            inputs.stylix.nixosModules.stylix
            inputs.chaotic.nixosModules.default
            ./hosts/nano.nix
            ./roles/desktop.nix
            ./sys/impermanence.nix
            ./sys/backups.nix
            ./sys/nfs.nix
            ./sys/syncthing.nix
          ];
        };
        sankara = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit pkgs-unstable;
          };
      	  modules = [
            inputs.stylix.nixosModules.stylix
            inputs.chaotic.nixosModules.default
            ./hosts/sankara.nix
            ./roles/server.nix
            ./sys/impermanence.nix
            ./sys/syncthing.nix
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

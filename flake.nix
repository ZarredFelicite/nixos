{
  description = "Zarred's NixOS flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable-small";
    # Keep Ollama CUDA on the last known-good revision until the 0.32.x nvcc regression is fixed.
    nixpkgs-ollama.url = "github:nixos/nixpkgs/9ab0784f4b4b98a4f100d4cb2245d791cdccf70a";
    # Match Titan's GPU stack to the known-working portable USB generation.
    nixpkgs-titan-gpu.url = "github:NixOS/nixpkgs/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7";
    nixpkgs-quickshell.url = "github:nixos/nixpkgs/8ee95bcb238069810a968efbf2bba8e4d6ff11a6";
    nixpkgs-brave-origin.url = "github:Daniel-42-z/brave-origin-flake/bbe5b55e46d3f842ef52a2db961eb0244ec2cbd4";
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    home-manager = { url = "github:nix-community/home-manager/release-25.11"; inputs.nixpkgs.follows = "nixpkgs"; };
    nur = { url = "github:nix-community/NUR"; };
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware/662bd6e312d2c8b212e32cb377abaee190749320";
    disko = { url = "github:nix-community/disko"; inputs.nixpkgs.follows = "nixpkgs"; };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # X1 Nano settings are vendored locally; nixos-hardware also supports Titan.
    impermanence.url = "github:nix-community/impermanence";
    stylix.url = "github:danth/stylix/release-25.11";
    sops-nix.url = "github:Mic92/sops-nix";

    rose-pine-hyprcursor = { url = "github:ndom91/rose-pine-hyprcursor"; };
    flake-compat.url = "github:nix-community/flake-compat";
    vigiland.url = "github:jappie3/vigiland";
    ignis = { url = "github:ignis-sh/ignis"; inputs.nixpkgs.follows = "nixpkgs-unstable"; };
    # astal.url = "github:aylur/astal";
    # ags.url = "github:aylur/ags";

    # nix-vscode-extensions = { url = "github:nix-community/nix-vscode-extensions"; inputs.nixpkgs.follows = "nixpkgs-unstable"; };
    nixvim = { url = "github:nix-community/nixvim"; }; # nixvim needs it's own nixpkgs
    spicetify-nix = { url = "github:Gerg-L/spicetify-nix"; inputs.nixpkgs.follows = "nixpkgs"; };
    # INFO:. does not have opencode compat. mcp-servers-nix = { url = "github:natsukium/mcp-servers-nix"; inputs.nixpkgs.follows = "nixpkgs-unstable"; };

    #claude-desktop = { url = "github:k3d3/claude-desktop-linux-flake"; inputs.nixpkgs.follows = "nixpkgs"; inputs.flake-utils.follows = "flake-utils"; };
    
    qmd = { url = "github:tobi/qmd"; };
    herdr = { url = "github:herdrdev/herdr/v0.8.2"; };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1";
    vicinae.url = "github:ZarredFelicite/vicinae-private/0934960b0f4e8d1bf82c7aaa3ea64dd71e55520f";
    recall = {
      url = "github:ZarredFelicite/recall-private/83f84be730292fd9ae57366dd699db1e9ad37506";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    ember-companion.url = "github:ZarredFelicite/ember-private/21f56e632775f40abe4f951f1fbaf1c5f0594f1f?dir=companion";
    print-vault = {
      url = "github:ZarredFelicite/print-vault-private/d7b744348cb1ef6e09bf4efad550297b5761643c";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicinae-printvault = {
      url = "github:ZarredFelicite/vicinae-printvault-private/58e6bdfed8cfe576402fd4cb3c1534552ac6b921";
      flake = false;
    };
  };
  outputs = {
    self, nixpkgs,
    nixpkgs-unstable, nixpkgs-ollama, nixpkgs-quickshell, nixpkgs-brave-origin, nixpkgs-titan-gpu, #nixpkgs-master,
    home-manager, determinate, ...  }@inputs:
    let
      lib = nixpkgs.lib // home-manager.lib;
      system = "x86_64-linux";
      permittedInsecurePackages = [
        "openclaw-2026.2.26"
      ];
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfree = true;
          inherit permittedInsecurePackages;
        };
        overlays = [
          # inputs.nix-vscode-extensions.overlays.default
        ];
      };
      pkgs-ollama = import nixpkgs-ollama {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-quickshell = import nixpkgs-quickshell {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-brave-origin = nixpkgs-brave-origin.packages.${system};
      pkgs-titan-gpu = import nixpkgs-titan-gpu {
        inherit system;
        config.allowUnfree = true;
      };
      rock4cModules = [
        inputs.nixos-hardware.nixosModules.rock-4c-plus
        ./hosts/rock4c.nix
      ];
      #pkgs-master = import nixpkgs-master {
      #  inherit system;
      #  config.allowUnfree = true;
      #};
    in {
      inherit lib;
      nixpkgs.overlays = (import ./overlays inputs);

      nixosConfigurations = {
        web = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs self;
            inherit pkgs-unstable pkgs-ollama pkgs-quickshell pkgs-brave-origin;
            #inherit pkgs-master;
            #inherit pkgs-stable;
          };
          modules = [
            inputs.stylix.nixosModules.stylix
            # determinate.nixosModules.default  # temporarily disabled on web to unstick nix-daemon/HM
            ./hosts/web.nix
            ./roles/desktop.nix
          ];
        };
        nano = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs self;
            inherit pkgs-unstable pkgs-quickshell pkgs-brave-origin;
            #inherit pkgs-master;
            #inherit pkgs-stable;
          };
          modules = [
            inputs.stylix.nixosModules.stylix
            ./hosts/nano.nix
            ./roles/desktop.nix
          ];
        };
        titan = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs self pkgs-unstable pkgs-quickshell pkgs-brave-origin pkgs-titan-gpu;
          };
          modules = [
            inputs.stylix.nixosModules.stylix
            inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
            inputs.disko.nixosModules.disko
            inputs.lanzaboote.nixosModules.lanzaboote
            ./hosts/titan.nix
            ./roles/desktop.nix
          ];
        };
        sankara = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs self;
            inherit pkgs-unstable pkgs-quickshell pkgs-brave-origin;
            #inherit pkgs-master;
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
            inputs.stylix.nixosModules.stylix
            ./hosts/nano_minimal.nix
            ./profiles/common.nix
          ];
        };
        rock4c = lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit inputs self;
          };
          modules = rock4cModules;
        };
        rock4c-image = lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit inputs self;
          };
          modules = rock4cModules ++ [ ./images/rock4c-sd-image.nix ];
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

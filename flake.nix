{
  description = "Zarred's NixOS flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable-small";
    nixpkgs-quickshell.url = "github:nixos/nixpkgs/8ee95bcb238069810a968efbf2bba8e4d6ff11a6";
    #nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    home-manager = { url = "github:nix-community/home-manager/release-25.11"; inputs.nixpkgs.follows = "nixpkgs"; };
    nur = { url = "github:nix-community/NUR"; };
    flake-utils.url = "github:numtide/flake-utils";

    # nixos-hardware removed; x1 nano settings are now vendored locally.
    impermanence.url = "github:nix-community/impermanence";
    stylix.url = "github:danth/stylix/release-25.11";
    sops-nix.url = "github:Mic92/sops-nix";

    rose-pine-hyprcursor = { url = "github:ndom91/rose-pine-hyprcursor"; };
    flake-compat.url = "github:nix-community/flake-compat";
    vigiland.url = "github:jappie3/vigiland";
    ignis = { url = "github:ignis-sh/ignis"; inputs.nixpkgs.follows = "nixpkgs-unstable"; };
    astal.url = "github:aylur/astal";
    ags.url = "github:aylur/ags";

    nix-vscode-extensions = { url = "github:nix-community/nix-vscode-extensions"; inputs.nixpkgs.follows = "nixpkgs-unstable"; };
    nixvim = { url = "github:nix-community/nixvim"; }; # nixvim needs it's own nixpkgs
    spicetify-nix = { url = "github:Gerg-L/spicetify-nix"; inputs.nixpkgs.follows = "nixpkgs"; };

    # INFO:. does not have opencode compat. mcp-servers-nix = { url = "github:natsukium/mcp-servers-nix"; inputs.nixpkgs.follows = "nixpkgs-unstable"; };

    #claude-desktop = { url = "github:k3d3/claude-desktop-linux-flake"; inputs.nixpkgs.follows = "nixpkgs"; inputs.flake-utils.follows = "flake-utils"; };
    
    qmd = { url = "github:tobi/qmd"; };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1";
    vicinae.url = "path:/home/zarred/dev/vicinae";
  };
  outputs = {
    self, nixpkgs,
    nixpkgs-unstable, nixpkgs-quickshell, #nixpkgs-master,
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
          inputs.nix-vscode-extensions.overlays.default
        ];
      };
      pkgs-quickshell = import nixpkgs-quickshell {
        inherit system;
        config.allowUnfree = true;
      };
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
            inherit pkgs-unstable pkgs-quickshell;
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
            inherit pkgs-unstable pkgs-quickshell;
            #inherit pkgs-master;
            #inherit pkgs-stable;
          };
          modules = [
            inputs.stylix.nixosModules.stylix
            ./hosts/nano.nix
            ./roles/desktop.nix
          ];
        };
        sankara = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs self;
            inherit pkgs-unstable pkgs-quickshell;
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

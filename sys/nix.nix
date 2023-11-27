{ pkgs, config, lib, inputs, ... }: {
  nix = {
    # Make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
    registry.nixpkgs.to = { type = "path"; path = pkgs.path; };
    #registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    settings = {
      trusted-users = [ "zarred" "nixremote" ];
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      builders-use-substitutes = true;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://anyrun.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
      ];
    };
  };
  # Perform garbage collection weekly to maintain low disk usage
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
   # Make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake.
  # environment.etc."nix/inputs/nixpkgs".source = "${nixpkgs}";

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      nur = import (builtins.fetchTarball {
        url = "https://github.com/nix-community/NUR/archive/master.tar.gz";
        sha256 = "08pfv4dk1hd10zz56hx6f1h0qh32z6jl3jvdkqabm2xgkkfvfyxl";
        }) {inherit pkgs; };
    };
  };

  nix.distributedBuilds = true;
  nix.buildMachines = [
    #{
    #  hostName = "sankara";
    #  sshUser = "nixremote";
    #  sshKey = "/home/zarred/.ssh/nixremote";
    #  system = "x86_64-linux";
    #  protocol = "ssh-ng";
    #  maxJobs = 1;
    #  speedFactor = 2;
    #  supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    #  mandatoryFeatures = [ ];
    #}
    #{
    #  hostName = "web";
    #  sshUser = "nixremote";
    #  sshKey = "/home/zarred/.ssh/nixremote";
    #  system = "x86_64-linux";
    #  protocol = "ssh-ng";
    #  maxJobs = 1;
    #  speedFactor = 1;
    #  supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    #  mandatoryFeatures = [ ];
    #}
  ];
  #systemd.services.nix-daemon = {
  #  environment.TMPDIR = "/var/cache/nix";
  #  serviceConfig.CacheDirectory = "nix";
  #};
  environment.variables.NIX_REMOTE = "daemon";
}

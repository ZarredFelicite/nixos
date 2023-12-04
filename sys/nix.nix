{ pkgs, config, lib, inputs, ... }: {
  nix = {
    # Make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
    #registry.nixpkgs.to = { type = "path"; path = pkgs.path; };
    registry = lib.mapAttrs (_: flake: {inherit flake; }) inputs;
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
      trusted-substituters = ["https://ai.cachix.org"];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
        "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
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
        #sha256 = "08i5hv8rilf9v7jvfbjvbb2gl0xxza91wrib4xzvknpb1ayw37dn";
        #sha256 = "1bm79vqwikhpg99w966ipdci2nr9xwf6z2yj356l5fsl75aaixfn";
        #sha256 = "173rd13r09bx36gi722p5hfwddpn6pdvzcz9ww8ka1sa1j90jfwl";
        #sha256 = "1hqxkrn46m6s197d2llkr2jxhm0b4hvv49746vwhc3mrsqpyy9il";
        sha256 = "0f918b3prd34h3njxi28l7bhz46wnvll2qmw1q8bg2fsqsr9pz60";
        }) {inherit pkgs; };
    };
  };

  nix.distributedBuilds = false;
  nix.buildMachines = [
    {
      hostName = "web";
      sshUser = "nixremote";
      sshKey = "/root/.ssh/nixremote";
      system = "x86_64-linux";
      protocol = "ssh-ng";
      maxJobs = 1;
      speedFactor = 1;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      mandatoryFeatures = [ ];
    }
    #{
    #  hostName = "sankara";
    #  sshUser = "nixremote";
    #  sshKey = "/root/.ssh/nixremote";
    #  system = "x86_64-linux";
    #  protocol = "ssh-ng";
    #  maxJobs = 1;
    #  speedFactor = 2;
    #  supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    #  mandatoryFeatures = [ ];
    #}
  ];
  #systemd.services.nix-daemon = {
  #  environment.TMPDIR = "/var/cache/nix";
  #  serviceConfig.CacheDirectory = "nix";
  #};
  environment.variables.NIX_REMOTE = "daemon";
  services.nix-serve = {
    enable = true;
    secretKeyFile = config.sops.secrets.binary-cache-key.path;
  };
}

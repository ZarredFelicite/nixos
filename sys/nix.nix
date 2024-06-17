{ pkgs, config, lib, inputs, ... }: {
  nix = {
    # Make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
    #registry.nixpkgs.to = { type = "path"; path = pkgs.path; };
    registry = lib.mapAttrs (_: flake: {inherit flake; }) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    settings = {
      #trusted-users = [ "zarred" "nixremote" ];
      trusted-users = [ "zarred" ];
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      builders-use-substitutes = true;
      substituters = [
        #"https://nixcache.zar.red"
        #"ssh://zarred@web"
        #"http://binarycache.zar.red"
        "https://cache.nixos.org"
        "https://cuda-maintainers.cachix.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        #"https://anyrun.cachix.org"
      ];
      trusted-substituters = ["https://ai.cachix.org"];
      trusted-public-keys = [
        #"binarycache.zar.red:/vYeoLG2d93laC//gtvofCCf8Jv4lZWOtle/cLeCXkByyuC5dPFrrSDvG/XPfbpabYzUaqSxOgUMIi5cK7tNDA=="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        #"anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
        "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
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
  nixpkgs.overlays = [
    inputs.nur.overlay
    (final: prev: {
      nodePackages = prev.nodePackages // {
        inherit (inputs.nixpkgs-fixes.legacyPackages.${prev.system}.nodePackages) bash-language-server;
      };
    })
  ];
  nixpkgs.config.allowUnfree = true;

  nix.distributedBuilds = false;
  #nix.buildMachines = [
  #  {
  #    hostName = "web";
  #    sshUser = "nixremote";
  #    sshKey = "/root/.ssh/nixremote";
  #    system = "x86_64-linux";
  #    protocol = "ssh-ng";
  #    maxJobs = 1;
  #    speedFactor = 1;
  #    supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
  #    mandatoryFeatures = [ ];
  #  }
  #  #{
  #  #  hostName = "sankara";
  #  #  sshUser = "nixremote";
  #  #  sshKey = "/root/.ssh/nixremote";
  #  #  system = "x86_64-linux";
  #  #  protocol = "ssh-ng";
  #  #  maxJobs = 1;
  #  #  speedFactor = 2;
  #  #  supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
  #  #  mandatoryFeatures = [ ];
  #  #}
  #];
  #systemd.services.nix-daemon = {
  #  environment.TMPDIR = "/var/cache/nix";
  #  serviceConfig.CacheDirectory = "nix";
  #};
  environment.variables.NIX_REMOTE = "daemon";
  nix.sshServe = {
    enable = false;
    keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEr5Pg9hm9lQDhobHUmn1q5R9XBXIv9iEcGUz9u+Vo9G zarred@web"
    ];
  };
  services.nix-serve = {
    enable = false;
    secretKeyFile = config.sops.secrets.binary-cache-key.path;
  };
}

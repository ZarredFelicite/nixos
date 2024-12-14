{ pkgs, config, lib, inputs, ... }: {
  environment.variables.NIX_REMOTE = "daemon";
  nix = {
    # Make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
    #registry.nixpkgs.to = { type = "path"; path = pkgs.path; };
    registry = lib.mapAttrs (_: flake: {inherit flake; }) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      trusted-users = [ "nixremote" "zarred" ]; # "zarred"
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      builders-use-substitutes = true;
      substituters = [
        "ssh-ng://nixremote-web"
        "https://cache.nixos.org"
        "https://cuda-maintainers.cachix.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "web-binary-cache:Hsy/WnNAxGvN4SE7bzaBY68O+wkicqTE2fW5iaDFao0="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
      secret-key-files = config.sops.secrets.binary-cache-key.path;
    };
    sshServe = {
      enable = true;
      protocol = "ssh-ng";
      keys = [
        #"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEr5Pg9hm9lQDhobHUmn1q5R9XBXIv9iEcGUz9u+Vo9G zarred@web"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdeXfQX7Ql7RRrv4GGtwfet2q6p0dxUJac3dNLnU+BY root@nano"
      ];
    };
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "web";
        sshUser = "nixremote";
        sshKey = config.sops.secrets.nixremote-private.path;
        system = "x86_64-linux";
        protocol = "ssh-ng";
        maxJobs = 3;
        speedFactor = 5;
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
  };
   # Make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake.
  # environment.etc."nix/inputs/nixpkgs".source = "${nixpkgs}";
  nixpkgs = {
    overlays = [
      inputs.nur.overlays.default
      (final: prev: { rofi-calc = prev.rofi-calc.override { rofi-unwrapped = prev.rofi-wayland-unwrapped; }; })
    ];
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "olm-3.2.16"
      ];
    };
  };
  #systemd.services.nix-daemon = {
  #  environment.TMPDIR = "/var/cache/nix";
  #  serviceConfig.CacheDirectory = "nix";
  #};
}

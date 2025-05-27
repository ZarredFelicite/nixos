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
      trusted-users = [ "nixremote" "zarred" "root"];
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      builders-use-substitutes = true;
      #max-jobs = 32;
      #cores = 16;
      substituters =
        lib.optionals (config.networking.hostName != "web") [ "ssh-ng://nixremote-web" ] ++ [
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
      enable = if config.networking.hostName == "web" then true else false;
      protocol = "ssh-ng";
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdeXfQX7Ql7RRrv4GGtwfet2q6p0dxUJac3dNLnU+BY root@nano"
      ];
    };
    distributedBuilds = if config.networking.hostName == "web" then false else true;
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
      (final: prev: rec {
        rofi-calc = prev.rofi-calc.override { rofi-unwrapped = prev.rofi-wayland-unwrapped; };
        #yt-dlp = pkgs.callPackage ../pkgs/python/yt-dlp {};
        # NOTE: no worky either
        #python312 = prev.python312.override {
        #  packageOverrides = final: prev: {
        #    yt-dlp = prev.yt-dlp.overridePythonAttrs(old: rec {
        #      pname = "yt-dlp";
        #      version = "2025.3.25";
        #      src = prev.fetchPypi {
        #        inherit version;
        #        pname = "yt_dlp";
        #        hash = "sha256-x/QlFvnfMdrvU8yiWQI5QBzzHbfE6spnZnz9gvLgric=";
        #      };
        #    });
        #  };
        #};
        # NOTE: Patch didn't work
        #orca-slicer = prev.orca-slicer.overrideAttrs (o: {
        #  patches = [ ( pkgs.fetchpatch {
        #    url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/369729.patch";
        #    hash = "sha256-+Ecwibp6YWM9GhxVvYpVPNLsKi8UJtSnXnqYsdFyN3Y=";

        #  }) ];
        #});
      })
    ];
    config = {
      allowUnfree = true;
      #allowUnfreePredicate = _: true;
      #allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      #  "copilot.vim"
      #];
      permittedInsecurePackages = [
        "olm-3.2.16"
        "dotnet-sdk-6.0.428" # sonarr
        "aspnetcore-runtime-6.0.36" # sonarr
      ];
    };
  };
  systemd.services.nix-daemon = {
    environment.TMPDIR = "/var/cache/nix";
    serviceConfig.CacheDirectory = "nix";
  };
  programs.nix-ld.enable = true;
}

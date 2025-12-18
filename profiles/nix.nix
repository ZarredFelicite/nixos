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
    extraOptions = ''
      !include ${config.sops.secrets.nixAccessTokens.path}
    '';
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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXK45mP2pGkokOWxJN0RXGIt4lkruzfwpbDJe1Y+GGP web"
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
      #inputs.nix-vscode-extensions.overlays.default
      #(final: prev: rec {
      #  rofi-calc = prev.rofi-calc.override { rofi-unwrapped = prev.rofi-wayland-unwrapped; };
      # NOTE: OBSOLETE
        #bindfs = pkgs.callPackage ../pkgs/bindfs {} ;
      #})
      # NOTE: OBSOLETE
      #(_: prev: {
      #  tailscale = prev.tailscale.overrideAttrs (old: {
      #    checkFlags =
      #      builtins.map (
      #        flag:
      #          if prev.lib.hasPrefix "-skip=" flag
      #          then flag + "|^TestGetList$|^TestIgnoreLocallyBoundPorts$|^TestPoller$"
      #          else flag
      #      )
      #      old.checkFlags;
      #  });
      #})
      # Override upstream youtube-transcript-api to use our local version
      (final: prev: rec {
        python3 = prev.python3.override {
          packageOverrides = pyfinal: pyprev: {
            #"youtube-transcript-api" = pyprev.callPackage ../pkgs/python/youtube-transcript-api {};
            youtube-transcript-api = pyprev.youtube-transcript-api.overridePythonAttrs ( oldAttrs: {
              version = "1.1.0";
              src = pkgs.fetchFromGitHub {
                owner = "jdepoix";
                repo = "youtube-transcript-api";
                tag = "v1.1.0";
                hash = "sha256-RCyv0RhJkxZ4RcM0Hv9Qd4KBBpbakjhhuX8V15GcMQA=";
              };
              doCheck = false;
            });
          };
        };
        python3Packages = python3.pkgs;
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

{ config, pkgs, pkgs-unstable, inputs, ... }:
let
  beetsXtractor = pkgs-unstable.python313Packages.callPackage ../../pkgs/python/beets-xtractor { };
  beetsWithXtractor = pkgs-unstable.beets.overridePythonAttrs (old: {
    propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [ beetsXtractor ];
  });
in {
  imports = [
    ./mpd_clients.nix
    ./mpv
    ./twitch.nix
    ./youtube/ytfzf.nix
    ./youtube/yt-dlp.nix
    inputs.spicetify-nix.homeManagerModules.spicetify
  ];
  home.packages = [
    #(pkgs.callPackage ../../pkgs/lowfi {})
    pkgs.lowfi
    pkgs-unstable.spotify-player
    (pkgs.writeShellScriptBin "spotify_player_tui" ''
      set -euo pipefail

      service=spotify-player.service
      was_active=0
      if systemctl --user --quiet is-active "$service"; then
        was_active=1
        systemctl --user stop "$service"
      fi

      restart_service() {
        if [ "$was_active" -eq 1 ]; then
          systemctl --user start "$service"
        fi
      }
      trap restart_service EXIT INT TERM

      ${pkgs-unstable.spotify-player}/bin/spotify_player "$@"
    '')
    pkgs-unstable.streamrip
  ];

  systemd.user.services.spotify-player = {
    Unit = {
      Description = "Spotify Player daemon";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "forking";
      ExecStart = "${pkgs-unstable.spotify-player}/bin/spotify_player --daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  xdg.configFile."easyeffects/output/autoeq.json".source = ./easyeffects/autoeq.json;
  services.easyeffects = {
    enable = false;
    preset = "autoeq" ;
  };
  stylix.targets.spicetify.enable = false;
  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
    in
    {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblockify
        hidePodcasts
        shuffle # shuffle+ (special characters are sanitized out of extension names)
      ];
      #theme = spicePkgs.themes.hazy;
      theme = spicePkgs.themes.text;
      colorScheme = "RosePine";
  };
  # CVE-2026-42052 is fixed in beets >= 2.10.0; stable nixpkgs is still on 2.5.1.
  programs.beets = {
    enable = true;
    package = beetsWithXtractor;
    mpdIntegration = {
      enableStats = true;
      enableUpdate = true;
      host = "localhost";
      port = config.services.mpd.network.port;
    };
    settings = {
      directory = "/mnt/gargantua/media/music";
      library = "/mnt/gargantua/media/music/data/beets.db";
      import = {
        move = true;
        write = true;
      };
      paths = {
        default = "%lower{$albumartist}/%lower{$album}%aunique{}-%left{$year,4}/$track-%lower{$title}";
        singleton = "%lower{$artist}/%lower{$title} - %left{$year,4}/01 - %lower{$title}";
        comp = "compilations/%lower{$album}%aunique{}-%left{$year,4}/$track-%lower{$title}";
      };
      plugins = [ "musicbrainz" "fetchart" "edit" "scrub" "lyrics" "zero" "info" "xtractor" ];
      zero = {
        auto = false;
        fields = [ "albumtype" "albumtypes" ];
        update_database = true;
        #fetchart:
        #discogs:
        #   source_weight: 0.0
        #musicbrainz:
        #   enabled: no
        #   source_weight: 0.8
      };
      xtractor = {
        auto = false;
        "dry-run" = false;
        write = true;
        threads = 1;
        force = false;
        keep_output = false;
        keep_profiles = false;
        output_path = "/mnt/gargantua/media/music/data/xtractor";
        essentia_extractor = "${pkgs-unstable.essentia-extractor}/bin/streaming_extractor_music";
        # nixpkgs essentia-extractor is built without Gaia, so high-level SVM
        # models fail. Keep xtractor on low-level features: bpm, loudness,
        # danceability, and beat count.
        high_level_targets = { };
        extractor_profile.highlevel = {
          compute = 0;
          svm_models = [ ];
        };
      };
    };
  };
  programs.gallery-dl = {
    enable = true;
    settings = {
      extractor.base-directory = "~/downloads";
    };
  };
}

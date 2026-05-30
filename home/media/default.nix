{ config, pkgs, pkgs-unstable, inputs, ... }:
let
  beetsXtractor = pkgs-unstable.python313Packages.callPackage ../../pkgs/python/beets-xtractor { };
  essentiaSvmModels = pkgs.callPackage ../../pkgs/essentia-svm-models.nix { };
  beetsWithXtractor = pkgs-unstable.beets.overridePythonAttrs (old: {
    propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [ beetsXtractor ];
  });
  svmModelPath = "${essentiaSvmModels}/share/essentia/svm_models";
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
    pkgs-unstable.streamrip
  ];
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
      plugins = [ "fetchart" "edit" "scrub" "lyrics" "zero" "info" "xtractor" ];
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
        "keep-output" = false;
        "keep-profiles" = false;
        output_path = "/mnt/gargantua/media/music/data/xtractor";
        essentia_extractor = "${pkgs-unstable.essentia-extractor}/bin/streaming_extractor_music";
        extractor_profile.highlevel.svm_models = [
          "${svmModelPath}/danceability.history"
          "${svmModelPath}/gender.history"
          "${svmModelPath}/genre_rosamerica.history"
          "${svmModelPath}/mood_acoustic.history"
          "${svmModelPath}/mood_aggressive.history"
          "${svmModelPath}/mood_electronic.history"
          "${svmModelPath}/mood_happy.history"
          "${svmModelPath}/mood_sad.history"
          "${svmModelPath}/mood_party.history"
          "${svmModelPath}/mood_relaxed.history"
          "${svmModelPath}/voice_instrumental.history"
          "${svmModelPath}/moods_mirex.history"
        ];
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

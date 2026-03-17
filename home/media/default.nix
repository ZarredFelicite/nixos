{ config, pkgs, pkgs-unstable, inputs, ... }: {
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
  programs.beets = {
    enable = true;
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
      plugins = [ "fetchart" "edit" "scrub" "lyrics" "acousticbrainz" "zero" "info" ];
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
    };
  };
  programs.gallery-dl = {
    enable = true;
    settings = {
      extractor.base-directory = "~/downloads";
    };
  };
}

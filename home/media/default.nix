{ config, pkgs, inputs, ... }: {
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
    enable = false;
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
        move = false;
        write = false;
      };
      paths = {
        default = "%lower{$albumartist}/%lower{$album%aunique{}}/$track - %lower{$title}";
        singleton = "%lower{$artist}/%lower{$title}";
        comp = "Compilations/%lower{$album%aunique{}}/$track %lower{$title}";
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
}

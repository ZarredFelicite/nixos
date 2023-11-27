{ ... }: {
  imports = [
    ./mpd_clients.nix
    ./mpv
    ./twitch.nix
    ./youtube/ytfzf.nix
    ./youtube/yt-dlp.nix
  ];
  xdg.configFile."easyeffects/output/autoeq.json".source = ./easyeffects/autoeq.json;
  services.easyeffects = {
    enable = true;
    preset = "autoeq" ;
  };
}

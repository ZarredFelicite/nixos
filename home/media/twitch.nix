{ pkgs, lib, osConfig, config, ... }: {
  home.packages = [
    pkgs.chatterino2
    pkgs.streamlink
  ];
  xdg.configFile."wtwitch/config.json".text = builtins.toJSON {
    player = "mpv";
    quality = "1080p60";
    colors = "true";
    printOfflineSubscriptions = "true";
    subscriptions = [
      { streamer = "anthonyz"; }
      { streamer = "buddha"; }
      { streamer = "zetarkgg"; }
      { streamer = "kyedae"; }
      { streamer = "ripoozi"; }
      { streamer = "jack"; }
      { streamer = "omie"; }
      { streamer = "nidas"; }
      { streamer = "pokelawls"; }
      { streamer = "nakeyjakey"; }
      { streamer = "hasanabi"; }
      { streamer = "willneff"; }
      { streamer = "michaelreeves"; }
      { streamer = "pokimane"; }
      { streamer = "moistcr1tikal"; }
      { streamer = "theprimeagen"; }
      { streamer = "yourragegaming"; }
      { streamer = "linustech"; }
      { streamer = "kaicenat"; }
      { streamer = "fanfan"; }
    ];
  };
  #xdg.configFile."wtwitch/api.json".source = config.lib.file.mkOutOfStoreSymlink /run/secrets/twitch-api-token;
  xdg.configFile."streamlink/config".text = ''
    twitch-api-header=Authorization=OAuth='$(cat ${osConfig.sops.secrets.twitch-oauth.path})'
    player=mpv
    player-args='--no-terminal'
    default-stream=best
  '';
}

{ lib, pkgs, config, ... }:
let
  cfg = config.services.wvkbd;
in {
  options.services.wvkbd.enable = lib.mkEnableOption "wvkbd service";
  config = lib.mkIf cfg.enable {
    systemd.user.services.wvkbd = {
      description = "wvkbd - On-screen keyboard for wlroots that sucks less";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      path = [ ];
      script = "${pkgs.wvkbd}/bin/wvkbd-mobintl --hidden -L 400 --bg 31294620 --fg 31294670";
    };
  };
}

{ config, lib, osConfig, pkgs-unstable, ... }:
let
  enabled = builtins.elem osConfig.networking.hostName [ "web" "titan" ];
  isTitan = osConfig.networking.hostName == "titan";
  stateDir = "/persist${config.home.homeDirectory}/.config/lan-mouse";
in
{
  home.packages = lib.mkIf isTitan [ pkgs-unstable.lan-mouse ];

  systemd.user.services.lan-mouse = lib.mkIf enabled {
    Unit = {
      Description = "Lan Mouse daemon";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs-unstable.lan-mouse}/bin/lan-mouse --config ${stateDir}/config.toml --cert-path ${stateDir}/lan-mouse.pem --capture-backend layer-shell --emulation-backend wlroots daemon";
      UMask = "0077";
      Restart = "on-failure";
      RestartSec = "3s";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}

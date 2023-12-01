{ pkgs, lib, config, ... }:
let
  cfg = config.services.hyprland-autoname-workspaces;
  mkHyprlandService = lib.recursiveUpdate {
    Unit.PartOf = ["hyprland-session.target"];
    Unit.After = ["hyprland-session.target"];
    Install.WantedBy = ["hyprland-session.target"];
  };
in {
  options.services.hyprland-autoname-workspaces.enable = lib.mkEnableOption "Autoname Hyprland workspaces service";
  config = lib.mkIf cfg.enable {
    xdg.configFile."hyprland-autoname-workspaces/config.toml".source = ./hyprland-autoname-workspaces.toml;
    systemd.user.services."hyprland-autoname-workspaces" = mkHyprlandService {
      Unit.Description = "Autoname Hyprland workspaces";
      Service.ExecStart = "${pkgs.hyprland-autoname-workspaces}/bin/hyprland-autoname-workspaces";
    };
    #systemd.user.timers."hyprland-autoname-workspaces-timer" = mkHyprlandService {
    #  Unit.Description = "Autoname Hyprland workspaces timer";
    #  Timer.OnBootSec = "5m";
    #  Timer.OnUnitActiveSec = "10";
    #  Timer.Unit = "hyprland-autoname-workspaces.service";
    #};
  };
}

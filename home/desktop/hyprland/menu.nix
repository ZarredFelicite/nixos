{ pkgs, pkgs-unstable, lib, inputs, ... }:
let
  vicinaePackage = inputs.vicinae.packages.${pkgs.system}.default;
  clipboardSelector = pkgs.writeShellScriptBin "clipboardSelector" "cliphist list | rofi -dmenu -matching prefix | cliphist decode | wl-copy ";
  hyprlauncherSettings = {
    general.grab_focus = true;
    cache.enabled = true;
    ui.window_size = "400 260";
    finders.desktop_icons = true;
  };
in {
  imports = [
    ../rofi/rofi.nix
  ];

  home.packages = [
    clipboardSelector
    pkgs-unstable.hyprlauncher
    vicinaePackage
  ];

  stylix.targets.vicinae.enable = false;

  xdg.configFile."vicinae/vicinae.json".text = builtins.toJSON {
    favicon_service = "twenty";
    pop_to_root_on_close = false;
    search_files_in_root = false;
    window.opacity = 0.7;
    launcher_window = {
      opacity = 0.7;
      size.width = 1100;
      size.height = 720;
    };
    theme = {
      name = "rose-pine";
      dark.name = "rose-pine";
      light.name = "rose-pine-dawn";
    };
  };

  programs.vicinae = {
    enable = true;
    package = vicinaePackage;
    systemd.enable = true;
    systemd.autoStart = true;
    settings = {};
  };

  xdg.configFile."hypr/hyprlauncher.conf".text =
    lib.hm.generators.toHyprconf { attrs = hyprlauncherSettings; };

  systemd.user.services.hyprlauncher = {
    Unit = {
      Description = "hyprlauncher";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs-unstable.hyprlauncher} -d";
      Restart = "on-failure";
      RestartSec = "10";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.rofi.enable = true;
}

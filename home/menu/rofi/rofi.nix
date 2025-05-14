{ pkgs, lib, osConfig, ... }: {
  stylix.targets.rofi.enable = false;
  programs.rofi = {
    package = pkgs.rofi-wayland;
    cycle = false;
    location = "center";
    font = lib.mkDefault "Iosevka Nerd Font 16";
    modes = [
      "drun"
      "run"
      "emoji"
      "ssh"
      "window"
      "combi"
      "keys"
      "filebrowser"
      "recursivebrowser"
      "calc"
      {
        name = "obsidian";
        path = lib.getExe pkgs.rofi-obsidian;
      }
    ];
    extraConfig = {
      auto-select = true;
      fixed-num-lines = false;
    };
    theme = ./theme.rasi;
    plugins = [
      pkgs.rofi-calc # overlay for rofi-wayland
      pkgs.rofi-emoji
    ];
  };
  home.packages = [
    pkgs.rofi-bluetooth
    #pkgs.rofi-mpd # NOTE: runtime error
    pkgs.rofi-obsidian
  ];
}

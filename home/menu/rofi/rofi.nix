{ config, pkgs, lib, ... }: {
  stylix.targets.rofi.enable = false;
  programs.rofi = {
    package = pkgs.rofi-wayland;
    cycle = false;
    location = "center";
    font = lib.mkDefault "Iosevka Nerd Font 16";
    extraConfig = {
      auto-select = true;
      fixed-num-lines = false;
    };
    theme = ./theme.rasi;
    plugins = [
      pkgs.rofi-calc
      pkgs.rofi-mpd
      pkgs.rofi-pass
      pkgs.rofi-emoji
      pkgs.rofi-bluetooth
    ];
  };
}

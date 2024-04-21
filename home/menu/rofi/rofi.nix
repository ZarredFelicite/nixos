{ config, pkgs, lib, ... }: {
  stylix.targets.rofi.enable = false;
  programs.rofi = {
    cycle = false;
    location = "top";
    font = lib.mkDefault "Iosevka Nerd Font 14";
    yoffset = 4;
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

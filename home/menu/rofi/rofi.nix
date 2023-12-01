{ config, pkgs, lib, ... }: {
  stylix.targets.rofi.enable = false;
  programs.rofi = {
    package = pkgs.rofi-wayland.override { plugins = with pkgs; [
      rofi-emoji # https://github.com/Mange/rofi-emoji
      rofi-mpd # https://github.com/JakeStanger/Rofi_MPD
      rofi-pass # https://github.com/carnager/rofi-pass
      rofi-calc # https://github.com/svenstaro/rofi-calc
      rofi-bluetooth # https://github.com/nickclyde/rofi-bluetooth
      rofi-screenshot # https://github.com/ceuk/rofi-screenshot
    ]; };
    cycle = false;
    location = "top";
    font = lib.mkDefault "Iosevka NF 9";
    yoffset = 4;
    extraConfig = {
      auto-select = true;
      fixed-num-lines = false;
    };
    theme = ./theme.rasi;
  };
}

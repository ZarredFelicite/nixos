{ pkgs, lib, osConfig, ... }:
let
  # Rofi's Wayland layer should take initial focus without reserving it.
  rofiOnDemand = pkgs.rofi.override {
    rofi-unwrapped = pkgs.rofi-unwrapped.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace source/wayland/display.c \
          --replace-fail \
          'zwlr_layer_surface_v1_set_keyboard_interactivity(wayland->wlr_surface, 1);' \
          'zwlr_layer_surface_v1_set_keyboard_interactivity(wayland->wlr_surface, 2);'
      '';
    });
  };
in {
  stylix.targets.rofi.enable = false;
  programs.rofi = {
    package = rofiOnDemand;
    cycle = false;
    location = "center";
    font = lib.mkDefault "IosevkaTerm NFM 16";
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
      "nerdy"
      "games"
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
      pkgs.rofi-nerdy
      pkgs.rofi-games
    ];
  };
  home.packages = [
    pkgs.rofi-bluetooth
    #pkgs.rofi-mpd # NOTE: runtime error
    pkgs.rofi-obsidian
  ];
}

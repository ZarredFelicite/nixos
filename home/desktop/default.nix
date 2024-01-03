{ pkgs, inputs, lib, osConfig, ... }:
with lib; let
  mkHyprlandService = lib.recursiveUpdate {
    Unit.PartOf = ["hyprland-session.target"];
    Unit.After = ["hyprland-session.target"];
    Install.WantedBy = ["hyprland-session.target"];
  };
  ocr = pkgs.writeShellScriptBin "ocr" ''
    #!/bin/bash
    set -e
    hyprctl keyword animation "fadeOut,0,5,default"
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp -w 0 -b eebebe66)" /tmp/ocr.png
    hyprctl keyword animation "fadeOut,1,5,default"
    tesseract /tmp/ocr.png /tmp/ocr-output
    wl-copy < /tmp/ocr-output.txt
    notify-send "OCR" "Text copied!"
    rm /tmp/ocr-output.txt -f
  '';
  screenshot = pkgs.writeShellScriptBin "screenshot" ''
    #!/bin/bash
    set -e
    hyprctl keyword animation "fadeOut,0,5,default"
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp -w 0 -b 5e81ac66)" - \
      | ${pkgs.swappy}/bin/swappy -f -
    hyprctl keyword animation "fadeOut,1,5,default"
  '';
in {
  imports = [
    ./hyprland
    ./swaync
    ./notifications.nix
    ./waybar.nix
  ];
  wayland.windowManager.hyprland.enable = true;
  programs.waybar.enable = true;
  services.mako.enable = true;
  home.packages = with pkgs; [
    #swaynotificationcenter # Simple notification daemon with a GUI built for Sway
    catppuccin-cursors.mochaDark
    slurp # Select a region in a Wayland compositor
    tesseract # OCR engine
    swappy # A Wayland native snapshot editing tool, inspired by Snappy on macOS
    wayshot # A native, blazing-fast screenshot tool for wlroots based compositors such as sway and river
    wf-recorder # Utility program for screen recording of wlroots-based compositors
    ocr
    grim # Grab images from a Wayland compositor
    screenshot
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    cliphist # Wayland clipboard manager
    hyprpicker # A wlroots-compatible Wayland color picker that does not suck
  ];
  systemd.user.services.cliphist = mkHyprlandService {
    Unit.Description = "Clipboard history";
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${lib.getExe pkgs.cliphist} store";
      Restart = "always";
    };
  };
  xdg.configFile."gotify-desktop/config.toml".text = ''
    [gotify]
    url = "wss://gotify.zar.red"
    token = "YOUR_SECRET_TOKEN"
    auto_delete = false  # optional, if true, deletes messages that have been handled, defaults to false

    [notification]
    min_priority = 1  # optional, ignores messages with priority lower than given value

    [action]
    # optional, run the given command for each message, with the following environment variables set: GOTIFY_MSG_PRIORITY, GOTIFY_MSG_TITLE and GOTIFY_MSG_TEXT.
    on_msg_command = "/usr/bin/beep"
  '';
  systemd.user.services.gotify-desktop = mkHyprlandService {
    Unit.Description = "Small Gotify daemon to send messages as desktop notifications";
    Service = {
      ExecStart = "${pkgs.gotify-desktop}/bin/gotify-desktop";
      Restart = "always";
    };
  };
}

{ pkgs, inputs, lib, osConfig, ... }:
with lib; let
  mkHyprlandService = lib.recursiveUpdate {
    Unit.PartOf = ["hyprland-session.target"];
    Unit.After = ["hyprland-session.target"];
    Install.WantedBy = ["hyprland-session.target"];
  };
  cliphist = (pkgs.cliphist.overrideAttrs (_old: {
    src = pkgs.fetchFromGitHub {
      owner = "sentriz";
      repo = "cliphist";
      rev = "c49dcd26168f704324d90d23b9381f39c30572bd";
      sha256 = "sha256-2mn55DeF8Yxq5jwQAjAcvZAwAg+pZ4BkEitP6S2N0HY=";
    };
    vendorHash = "sha256-M5n7/QWQ5POWE4hSCMa0+GOVhEDCOILYqkSYIGoy/l0=";
  }));
in {
  imports = [
    ./hyprland
    ./swaync
    ./notifications.nix
    ./waybar.nix
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.variables = ["--all"];
  };
  programs.waybar.enable = true;
  services.mako.enable = true;
  home.packages = with pkgs; [
    #swaynotificationcenter # Simple notification daemon with a GUI built for Sway
    slurp # Select a region in a Wayland compositor
    tesseract # OCR engine
    swappy # A Wayland native snapshot editing tool, inspired by Snappy on macOS
    satty # A screenshot annotation tool inspired by Swappy and Flameshot
    wayshot # A native, blazing-fast screenshot tool for wlroots based compositors such as sway and river
    wf-recorder # Utility program for screen recording of wlroots-based compositors
    wl-screenrec # High performance wlroots screen recording, featuring hardware encoding
    grim # Grab images from a Wayland compositor
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    cliphist # Wayland clipboard manager
    hyprpicker # A wlroots-compatible Wayland color picker that does not suck
    wl-mirror # Mirrors an output onto a Wayland surface
    pipectl # a simple named pipe management utility
  ];
  systemd.user.services.cliphist = mkHyprlandService {
    Unit.Description = "Clipboard history";
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${lib.getExe cliphist} store";
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

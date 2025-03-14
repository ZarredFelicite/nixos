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
      rev = "v0.6.1";
      sha256 = "sha256-tImRbWjYCdIY8wVMibc5g5/qYZGwgT9pl4pWvY7BDlI=";
    };
  }));
in {
  imports = [
    ./hyprland
    ./swaync
    ./notifications.nix
    ./waybar
  ];
    # NOTE: test nixpkgs patch overlay
    #nixpkgs.overlays = [
    #  (final: prev: {
    #    wl-screenrec = prev.wl-screenrec.overrideAttrs (old: {
    #      patches = (old.patches or []) ++ [
    #        (prev.fetchpatch {
    #          url = "https://github.com/NixOS/nixpkgs/pull/353815/commits/a36b4d9ac9e2f4c42b145685a31ac8b58776e8cb.patch";
    #          hash = "";
    #        })
    #      ];
    #    });
    #  })
    #];
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.variables = ["--all"];
  };
  programs.waybar.enable = true;
  services.mako.enable = false;
  services.swaync.enable = true;
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
  xdg.configFile."gotify/cli.json".source = osConfig.sops.templates."gotify-cli.json".path;
  xdg.configFile."gotify-desktop/config.toml".source = osConfig.sops.templates."gotify-desktop-config.toml".path;
  systemd.user.services.gotify-desktop = mkHyprlandService {
    Unit.Description = "Small Gotify daemon to send messages as desktop notifications";
    Service = {
      ExecStart = "${pkgs.gotify-desktop}/bin/gotify-desktop";
      Restart = "always";
    };
  };
  systemd.user.services.nova-cache = mkHyprlandService {
    Unit.Description = "Cache some cmd outputs for fzf-nova menu";
    Service = {
      ExecStart = "/home/zarred/scripts/nova/nova-cmd-cache.sh";
      Restart = "always";
    };
  };
}

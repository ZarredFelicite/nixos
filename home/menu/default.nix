{ pkgs, pkgs-unstable, lib, ... }:
let
  #selectorScript = pkgs.writeShellScriptBin "selectorMenu" ''
  #  exec ${}
  #'';
  clipboardSelector = pkgs.writeShellScriptBin "clipboardSelector" "cliphist list | rofi -dmenu -matching prefix | cliphist decode | wl-copy ";
in {
  imports = [
    ./rofi/rofi.nix
    #inputs.anyrun.homeModules.default
  ];
  home.packages = [
    #selectorScript
    clipboardSelector
    pkgs-unstable.hyprlauncher
  ];
  programs.rofi.enable = true;
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    colors = {
      "fg" = lib.mkForce "#9ccfd8";
      "fg+" = lib.mkForce "#ebbcba";
    #  "hl" = "yellow";
    #  "hl+" = "red";
      "bg" = lib.mkForce "-1";
      "bg+" = lib.mkForce "-1";
      "gutter" = lib.mkForce "-1";
      "pointer" = lib.mkForce "#ebbcba";
      "border" = lib.mkForce "#6e6a86";
      "scrollbar" = lib.mkForce "#6e6a86";
      "info" = lib.mkForce "#6e6a86";
    };
    defaultCommand = "fd --type file --no-ignore";
    defaultOptions = [
      "--layout reverse"
      #"--border"
      "--info inline"
      "--no-separator"
      "--cycle"
      "--scroll-off 10"
      "--pointer '⏽'"
      "--marker '󰧟'"
      "--prompt '  '"
      "--gutter ' '"
      "--ansi"
      "-m"
      "--bind='ctrl-a:toggle-all,ctrl-j:replace-query,ctrl-p:change-preview-window(right,70%|down,40%|hidden),change:top'"
    ];
    fileWidgetCommand = "fd --type f";
    fileWidgetOptions = [ "--preview 'head {}'" ];
    historyWidgetOptions = [ "--sort" "--exact" ];
    tmux.enableShellIntegration = true;
  };
}

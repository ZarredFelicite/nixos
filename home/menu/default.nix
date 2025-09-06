{ pkgs, lib, ... }:
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
      "gutter" = "-1";
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
      "--ansi"
      "-m"
      "--bind='ctrl-a:toggle-all,ctrl-j:replace-query,ctrl-p:change-preview-window(right,70%|down,40%|hidden),change:top'"
    ];
    fileWidgetCommand = "fd --type f";
    fileWidgetOptions = [ "--preview 'head {}'" ];
    historyWidgetOptions = [ "--sort" "--exact" ];
    tmux.enableShellIntegration = true;
  };
  #programs.anyrun = {
  #  enable = false;
  #  package = inputs.anyrun.packages.${pkgs.system}.anyrun-with-all-plugins;
  #  config = {
  #    plugins = with inputs.anyrun.packages.${pkgs.system}; [
  #      applications
  #      #dictionary
  #      kidex
  #      rink
  #      shell
  #      stdin
  #      symbols
  #      translate
  #      websearch
  #    ];
  #    x.fraction = 0.5;
  #    y.absolute = 0;
  #    width.fraction = 0.3;
  #    hideIcons = false;
  #    ignoreExclusiveZones = false;
  #    layer = "top";
  #    hidePluginInfo = true;
  #    closeOnClick = false;
  #    showResultsImmediately = false;
  #    maxEntries = null;
  #  };
  #  extraCss = ''
  #    @define-color fg-col #ebbcba;
  #    @define-color bg-col rgba(31, 29, 46, 0.5);
  #    @define-color selected-col rgba(150, 205, 251, 0.5);
  #    @define-color border-col rgba(30, 30, 46, 0.5);
  #    * {
  #      font-family: "Iosevka Nerd Font";
  #      font-size: 1rem;
  #      border-radius: 14px;
  #    }
  #    #window {
  #      background: transparent;
  #      background-color: transparent;
  #    }
  #    #main {
  #      color: @fg-col;
  #      background-color: transparent;
  #      background: transparent;
  #    }
  #    list#main {
  #      background-color: transparent;
  #      background: transparent;
  #    }
  #    box#main {
  #      background-color: transparent;
  #      background: transparent;
  #    }
  #    #entry {
  #      color: @fg-col;
  #      background-color: @bg-col;
  #      margin-top: 0;
  #      margin-bottom: 0;
  #      padding-top: 0;
  #      padding-bottom: 0;
  #    }
  #    box#match {
  #      color: @fg-col;
  #      background: @bg-col;
  #      border: 0px;
  #      padding: 2px;
  #    }
  #    #match:selected {
  #      color: @fg-col;
  #      background: @selected-col;
  #      border: 0px;
  #    }
  #  '';
  #  #extraConfigFiles."some-plugin.ron".text = ''
  #  #  Config(
  #  #    // for any other plugin
  #  #    // this file will be put in ~/.config/anyrun/some-plugin.ron
  #  #    // refer to docs of xdg.configFile for available options
  #  #  )
  #  #'';
  #};
}

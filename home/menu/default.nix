{ pkgs, pkgs-unstable, lib, inputs, ... }:
let
  vicinaePackage = inputs.vicinae.packages.${pkgs.system}.default;
  #selectorScript = pkgs.writeShellScriptBin "selectorMenu" ''
  #  exec ${}
  #'';
  clipboardSelector = pkgs.writeShellScriptBin "clipboardSelector" "cliphist list | rofi -dmenu -matching prefix | cliphist decode | wl-copy ";
  hyprlauncherSettings = {
    general.grab_focus = true;
    cache.enabled = true;
    ui.window_size = "400 260";
    finders.desktop_icons = true;
  };
in {
  imports = [
    ./rofi/rofi.nix
    #inputs.anyrun.homeModules.default
  ];
  home.packages = [
    #selectorScript
    clipboardSelector
    pkgs-unstable.hyprlauncher
    vicinaePackage
  ];

  # Vicinae launcher (like Raycast for Wayland)
  stylix.targets.vicinae.enable = false;

  # Create vicinae.json directly with settings (more reliable than symlinks to store)
  xdg.configFile."vicinae/vicinae.json".text = builtins.toJSON {
    favicon_service = "twenty";
    pop_to_root_on_close = false;
    search_files_in_root = false;
    window.opacity = 0.7;
    launcher_window = {
      opacity = 0.7;
      size.width = 1100;
      size.height = 720;
    };
    theme = {
      name = "rose-pine";
      dark.name = "rose-pine";
      light.name = "rose-pine-dawn";
    };
  };

  programs.vicinae = {
    enable = true;
    package = vicinaePackage;
    systemd.enable = true;
    systemd.autoStart = true;
    # Settings now in xdg.configFile."vicinae/settings.json"
    settings = {};
  };

  # Hyprlauncher (no HM module on this channel, wire declaratively)
  xdg.configFile."hypr/hyprlauncher.conf".text =
    lib.hm.generators.toHyprconf { attrs = hyprlauncherSettings; };

  systemd.user.services.hyprlauncher = {
    Unit = {
      Description = "hyprlauncher";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs-unstable.hyprlauncher} -d";
      Restart = "on-failure";
      RestartSec = "10";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

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

{ pkgs, pkgs-unstable, inputs, lib, osConfig, config, ... }:
with lib; let
  mkHyprlandService = lib.recursiveUpdate {
    Unit.PartOf = ["hyprland-session.target"];
    Unit.After = ["hyprland-session.target"];
    Install.WantedBy = ["hyprland-session.target"];
  };
  #cliphist = (pkgs.cliphist.overrideAttrs (_old: {
  #  src = pkgs.fetchFromGitHub {
  #    owner = "sentriz";
  #    repo = "cliphist";
  #    rev = "v0.6.1";
  #    sha256 = "sha256-tImRbWjYCdIY8wVMibc5g5/qYZGwgT9pl4pWvY7BDlI=";
  #  };
  #}));
in {
  imports = [
    ./hyprland
    ./swaync
    ./notifications.nix
    ./waybar
    ./vscode.nix
    ../../modules/quickshell.nix
    inputs.ags.homeManagerModules.default
  ];

  # Content merged from home/desktop.nix (the file)
  programs.hyprlock.enable = true; # From home/desktop.nix
  programs.swaylock.enable = true; # From home/desktop.nix
  programs.password-store.enable = true; # From home/desktop.nix
  services.hypridle.enable = true; # From home/desktop.nix

  programs.ags = {
    enable = true;
    extraPackages = with pkgs; [
      inputs.astal.packages.${pkgs.system}.battery
      inputs.astal.packages.${pkgs.system}.hyprland
      fzf
    ];
  };

  home.packages = [
    pkgs.slurp
    pkgs.tesseract
    pkgs.swappy
    pkgs.satty
    pkgs.wayshot
    pkgs.wf-recorder
    pkgs.wl-screenrec
    pkgs.grim
    pkgs.wl-clipboard
    pkgs.cliphist
    pkgs.hyprpicker
    pkgs.wl-mirror
    pkgs.pipectl

    pkgs.wev
    pkgs.transmission_4
    pkgs.libnotify
    pkgs.cava
    pkgs.songrec
    pkgs.sox
    pkgs.decibels
    pkgs.amberol
    pkgs.glow
    pkgs.nb
    pkgs-unstable.obsidian
    pkgs.orca-slicer
    pkgs.vtk
    pkgs.xdg-utils
    pkgs.glib
    pkgs.dracula-theme
    pkgs.wtype
    pkgs.signal-desktop
    pkgs.telegram-desktop
    pkgs.zoom-us
    pkgs.v4l-utils
    (pkgs.discord.override { withOpenASAR = true; withVencord = true; })
    pkgs.materia-kde-theme
    pkgs.libsForQt5.qtstyleplugin-kvantum
    pkgs.gimp
    pkgs.pinta
    pkgs.code-cursor
    #pkgs-unstable.libsForQt5.qt5.qtgraphicaleffects
    #inputs.claude-desktop.packages.${pkgs.system}.claude-desktop # Corrected system reference
    inputs.ignis.packages.x86_64-linux.ignis
  ];
  home.sessionVariables = { # From home/desktop.nix
    MOZ_ENABLE_WAYLAND = 1;
    XDG_CURRENT_DESKTOP = "hyprland";
    MOZ_USE_XINPUT2 = "1";
    GDK_SCALE = 1;
    GDK_DPI_SCALE = 1;
    QT_AUTO_SCREEN_SET_FACTOR = 0;
    QT_SCALE_FACTOR = 1;
    QT_FONT_DPI = 100;
    QT_QPA_PLATFORM = "wayland";
    XCURSOR_SIZE = 24;
    GTK_USE_PORTAL = 1;
    NBRC_PATH = "/home/zarred/.config/nb/nbrc";
    # TERM = "xterm-kitty"; # This might be better set in a terminal-specific profile
  };

  programs.pqiv = {
    enable = true;
    settings = {
      options = {
        lazy-load = true;
        hide-info-box = true;
        background-pattern = "black";
        thumbnail-size = "256x256";
        command-1 = "thunar";
      };
    };
    extraConfig = ''
      [actions]
      set_cursor_auto_hide(1)

      [keybindings]
      t { montage_mode_enter() }
      @MONTAGE {
        t { montage_mode_return_cancel() }
      }
    '';
  };
  programs.swayimg = {
    enable = true;
    settings = import ./swayimg.nix;
  };
  programs.zathura = {
    enable = true;
    options = {
      guioptions = "v";
      adjust-open = "width";
      statusbar-basename = true;
      render-loading = false;
      scroll-step = 120;
    };
  };
  programs.obs-studio = { enable = true; }; # From home/desktop.nix

  # Original services from home/desktop/default.nix
  systemd.user.services.cliphist = mkHyprlandService {
    Unit.Description = "Clipboard history";
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${lib.getExe pkgs.cliphist} store";
      Restart = "always";
    };
  };
  xdg.configFile."gotify/cli.json".source = osConfig.sops.templates."gotify-cli.json".path; # from original
  xdg.configFile."gotify-desktop/config.toml".source = osConfig.sops.templates."gotify-desktop-config.toml".path; # from original
  systemd.user.services.gotify-desktop = mkHyprlandService { # from original
    Unit.Description = "Small Gotify daemon to send messages as desktop notifications";
    Service = {
      ExecStart = "${pkgs.gotify-desktop}/bin/gotify-desktop";
      Restart = "always";
    };
  };
  systemd.user.services.nova-cache = mkHyprlandService { # from original
    Unit.Description = "Cache some cmd outputs for fzf-nova menu";
    Service = {
      ExecStart = "/home/zarred/scripts/nova/nova-cmd-cache.sh";
      Restart = "always";
    };
  };

  # Services merged from home/desktop.nix (the file)
  services.fusuma = { # From home/desktop.nix
    enable = false;
    extraPackages = with pkgs; [ coreutils hyprland ];
    settings = {
      threshold = { swipe = 0.1; };
      interval = { swipe = 0.7; };
      swipe = {
        "3" = {
          left = { command = "hyprctl dispatch workspace +1"; };
          right = { command = "hyprctl dispatch workspace -1"; };
        };
      };
    };
  };
  services.playerctld.enable = true; # From home/desktop.nix
  services.kdeconnect = { # From home/desktop.nix
    enable = true;
    indicator = true;
  };

  # XDG entries merged from home/desktop.nix (the file)
  xdg.desktopEntries.OrcaSlicer = { # From home/desktop.nix
    name = "OrcaSlicer";
    genericName = "3D Printing Software";
    icon = "OrcaSlicer";
    exec = "env __GLX_VENDOR_LIBRARY_NAME=mesa __EGL_VENDOR_LIBRARY_FILENAMES=${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json ${pkgs.orca-slicer}/bin/orca-slicer";
    terminal = false;
    type = "Application";
    mimeType = ["model/stl" "model/3mf" "application/vnd.ms-3mfdocument" "application/prs.wavefront-obj" "application/x-amf" "x-scheme-handler/orcaslicer"];
    categories = ["Graphics" "3DGraphics" "Engineering"];
    startupNotify = false;
  };

  # Original wayland/mako settings from home/desktop/default.nix
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.variables = ["--all"];
  };
  programs.quickshell = {
    enable = true;
    package = (pkgs.callPackage ../../pkgs/quickshell.nix {});
    activeConfig = "primary";
    systemd.enable = true;
    systemd.target = "hyprland-session.target";
  };
  programs.waybar.enable = false;
  services.mako.enable = false; # This was in original home/desktop/default.nix
  services.swaync.enable = true; # This was in original home/desktop/default.nix

  # Ensure pkgs.system is used for inputs.claude-desktop if it was ${system}
  # This is handled by `inputs.claude-desktop.packages.${pkgs.system}.claude-desktop` above.
}

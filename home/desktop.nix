{ self, inputs, outputs, config, pkgs, lib, ... }:
let
  pinentryRofi = pkgs.writeShellApplication {
    name= "pinentry-rofi-with-env";
    text = ''
      PATH="$PATH:${pkgs.coreutils}/bin:${pkgs.rofi}/bin"
      "${pkgs.pinentry-rofi}/bin/pinentry-rofi" "$@"
    '';
  };
in {
  imports = [
    ./core.nix
    ./browser
    ./desktop
    ./theme
    ./gaming
  ];
  programs.swaylock.enable = true;
  programs.password-store.enable = true;
  services.swayidle.enable = true;
  services.gpg-agent.extraConfig = ''
    pinentry-program ${pinentryRofi}/bin/pinentry-rofi-with-env
    allow-preset-passphrase
  '';
  services.gpg-agent.pinentryPackage = null;
  home.packages = with pkgs; [
    # wayland tools
    wev # Wayland event viewer
    # networking
    transmission_4 # A fast, easy and free BitTorrent client
    # notifications
    libnotify # A library that sends desktop notifications to a notification daemon
    gotify-cli # A command line interface for pushing messages to gotify/server
    # audio
    cava # Console-based Audio Visualizer for Alsa
    songrec # An open-source Shazam client for Linux, written in Rust
    sox # Sample Rate Converter for audio
    # productivity
    glow # Render markdown on the CLI, with pizzazz!
    nb # A command line note-taking, bookmarking, archiving, and knowledge base application
    # 3d printing
    f3d # Fast and minimalist 3D viewer using VTK
    prusa-slicer # G-code generator for 3D printer
    #orca-slicer
    vtk # Open source libraries for 3D computer graphics, image processing and visualization
    # misc
    xdg-utils # for opening default programs when clicking links
    glib # gsettings
    dracula-theme # gtk theme
    gnome3.adwaita-icon-theme  # default gnome cursors
    sunshine # Sunshine is a Game stream host for Moonlight.
    wtype # xdotool type for wayland
    # messaging
    signal-desktop # Private, simple, and secure messenger
    telegram-desktop # Telegram Desktop messaging app
    caprine-bin # An elegant Facebook Messenger desktop app
    zoom-us # zoom.us video conferencing application
    discord # All-in-one cross-platform voice and text chat for gamers
    # themeing
    materia-kde-theme
    libsForQt5.qtstyleplugin-kvantum
    # security
    pinentry-rofi
  ];
  home.sessionVariables = {
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
    #TERM = "xterm-kitty";
    NBRC_PATH = "/home/zarred/.config/nb/nbrc";
  };
  programs = {
    imv = {
      enable = true;
    };
    zathura = {
      enable = true;
      options = {
        guioptions = "v";
        adjust-open = "width";
        statusbar-basename = true;
        render-loading = false;
        scroll-step = 120;
      };
    };
    obs-studio = {
      enable = true;
    };
  };
  services = {
    fusuma = {
      enable = false;
      extraPackages = with pkgs; [ coreutils hyprland ];
      settings = {
        threshold = {
          swipe = 0.1;
        };
        interval = {
          swipe = 0.7;
        };
        swipe = {
          "3" = {
            left = {
              command = "hyprctl dispatch workspace +1";
            };
            right = {
              command = "hyprctl dispatch workspace -1";
            };
          };
        };
      };
    };
    playerctld.enable = true;
    kdeconnect = {
      enable = true;
      indicator = true;
    };
  };
}

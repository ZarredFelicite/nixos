{ self, inputs, outputs, config, pkgs, pkgs-unstable, lib, ... }: {
  imports = [
    ./core.nix
    ./browser
    ./desktop
    ./theme
    ./gaming
  ];
  programs.hyprlock.enable = true;
  programs.password-store.enable = true;
  services.hypridle.enable = true;
  home.packages = ( with pkgs-unstable; [
    ] ) ++
    ( with pkgs; [
    # wayland tools
    wev # Wayland event viewer
    # networking
    transmission_4 # A fast, easy and free BitTorrent client
    # notifications
    libnotify # A library that sends desktop notifications to a notification daemon
    # audio
    cava # Console-based Audio Visualizer for Alsa
    songrec # An open-source Shazam client for Linux, written in Rust
    sox # Sample Rate Converter for audio
    # productivity
    glow # Render markdown on the CLI, with pizzazz!
    nb # A command line note-taking, bookmarking, archiving, and knowledge base application
    # 3d printing
    f3d # Fast and minimalist 3D viewer using VTK
    # TODO: broken orca-slicer # G-code generator for 3D printers (Bambu, Prusa, Voron, VzBot, RatRig, Creality, etc
    # prusa-slicer # G-code generator for 3D printer
    # bambu-studio # PC Software for BambuLab's 3D printers
    vtk # Open source libraries for 3D computer graphics, image processing and visualization
    # misc
    xdg-utils # for opening default programs when clicking links
    glib # gsettings
    dracula-theme # gtk theme
    #sunshine # Sunshine is a Game stream host for Moonlight.
    wtype # xdotool type for wayland
    # messaging
    signal-desktop # Private, simple, and secure messenger
    telegram-desktop # Telegram Desktop messaging app
    caprine-bin # An elegant Facebook Messenger desktop app
    zoom-us # zoom.us video conferencing application
    #discord # All-in-one cross-platform voice and text chat for gamers
    # themeing
    materia-kde-theme
    libsForQt5.qtstyleplugin-kvantum
    # image viewer
    swayimg
    gimp
  ] );
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
    feh.enable = true;
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
  # TODO: broken
    #xdg.desktopEntries.OrcaSlicer = {
    #  name = "OrcaSlicer";
    #  genericName = "3D Printing Software";
    #  icon = "OrcaSlicer";
    #  exec = "env __GLX_VENDOR_LIBRARY_NAME=mesa __EGL_VENDOR_LIBRARY_FILENAMES=${pkgs.mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json ${pkgs.orca-slicer}/bin/orca-slicer";
    #  terminal = false;
    #  type = "Application";
    #  mimeType = ["model/stl" "model/3mf" "application/vnd.ms-3mfdocument" "application/prs.wavefront-obj" "application/x-amf" "x-scheme-handler/orcaslicer"];
    #  categories = ["Graphics" "3DGraphics" "Engineering"];
    #  startupNotify = false;
    #};
  xdg.configFile."swayimg/config".text = ''
      [general]
      #scale = optimal # Initial scale (optimal/fit/width/height/fill/real)
      #fullscreen = no
      #antialiasing = no
      #transparency = grid # Background for transparent images (none/grid/RGB, e.g. #112233)
      #position = parent # Window position (parent or absolute coordinates, e.g. 100,200)
      # Window size (parent, image, or absolute size, e.g. 800,600)
      size = image
      #background = none # Window background mode/color (none/RGB, e.g. #112233)
      #slideshow = no # Run slideshow at startup (yes/no)
      #slideshow_time = 3 # Slideshow image display time (seconds)

      #[list]
      #order = alpha # Default order (none/alpha/random)
      #loop = yes # Looping list of images (yes/no)
      #recursive = no # Read directories recursively (yes/no)
      #all = yes # Open all files in the start directory (yes/no)

      #[font]
      #name = monospace
      #size = 14
      #color = #cccccc
      #shadow = #000000

      #[info]
      #mode = full # Mode on startup (off/brief/full)
      #full.topleft = name,format,filesize,imagesize,exif # Display scheme for the "full" mode: position = content
      #full.topright = index
      #full.bottomleft = scale,frame
      #full.bottomright = status
      #brief.topleft = index # Display scheme for the "brief" mode: position = content
      #brief.topright = none
      #brief.bottomleft = none
      #brief.bottomright = status

      #[keys]
      #F1 = help
      #Home = first_file
      #End = last_file
      #Prior = prev_file
      #Next = next_file
      #Space = next_file
      #Shift+d = prev_dir
      #d = next_dir
      #Shift+o = prev_frame
      #o = next_frame
      #Shift+s = slideshow
      #s = animation
      #f = fullscreen
      #Left = step_left 10
      #Right = step_right 10
      #Up = step_up 10
      #Down = step_down 10
      #Equal = zoom +10
      #Plus = zoom +10
      #Minus = zoom -10
      #w = zoom width
      #Shift+w = zoom height
      #z = zoom fit
      #Shift+z = zoom fill
      #0 = zoom real
      #BackSpace = zoom optimal
      #bracketleft = rotate_left
      #bracketright = rotate_right
      #m = flip_vertical
      #Shift+m = flip_horizontal
      #a = antialiasing
      #r = reload
      #i = info
      #e = exec echo "Image: %"
      #Escape = exit
      #q = exit
  '';
}

{ pkgs, inputs, lib, osConfig, config, ... }:
let
  mkHyprlandService = lib.recursiveUpdate {
    Unit.PartOf = ["hyprland-session.target"];
    Unit.After = ["hyprland-session.target"];
    Install.WantedBy = ["hyprland-session.target"];
  };
in {
  imports = [
    #inputs.hyprland.homeManagerModules.default
    ./autoname-workspaces/hyprland-autoname-workspaces.nix
    ./rules.nix
    ./binds.nix
  ];
  stylix.targets.hyprland.enable = false;
  home.packages = [
    inputs.hyprlang.packages.${pkgs.hostPlatform.system}.hyprlang
    pkgs.hyprland-autoname-workspaces
    inputs.rose-pine-hyprcursor.packages.${pkgs.hostPlatform.system}.default
  ];
  services.hyprland-autoname-workspaces.enable = false;
  #programs.hyprlock.package = inputs.hyprlock.packages.${pkgs.hostPlatform.system}.hyprlock;
  programs.hyprlock.settings = {
    general = {
      hide_cursor = true;
      grace = 3;
      ignore_empty_input = true;
    };
    background = {
      monitor = "";
      path = "~/pictures/wallpapers/tarantula_nebula_nano.png";
      color = "rgba(25, 20, 20, 1.0)";
      blur_passes = 4;
      blur_size = 7;
      #noise = 0.0117
      #contrast = 0.8916
      brightness = 0.7;
      #vibrancy = 0.1696
      #vibrancy_darkness = 0.0
    };
    image = {
      monitor = "";
      path = "/home/zarred/documents/career/photos/ProfilePhoto.jpg";
      size = 150; # lesser side if not 1:1 ratio
      rounding = -1; # negative values mean circle
      border_size = 4;
      border_color = "rgb(38, 35, 58)";
      rotate = 0; # degrees, counter-clockwise
      #reload_time = -1; # seconds between reloading, 0 to reload with SIGUSR2
      #reload_cmd =  # command to get new path. if empty, old path will be used. don't run "follow" commands like tail -F
      position = "0, 200";
      halign = "center";
      valign = "center";
    };
    input-field = {
      monitor = "";
      size = "200, 50";
      outline_thickness = 3;
      dots_size = 0.33; # Scale of input-field height, 0.2 - 0.8
      dots_spacing = 0.15; # Scale of dots' absolute size, 0.0 - 1.0
      dots_center = false;
      dots_rounding = -1; # -1 default circle, -2 follow input-field rounding
      outer_color = "rgb(31748f)";
      inner_color = "rgb(26233a)";
      font_color = "rgb(c4a7e7)";
      fade_on_empty = true;
      fade_timeout = 1000; # Milliseconds before fade_on_empty is triggered.
      placeholder_text = "<i>Input Password...</i>"; # Text rendered in the input box when it's empty.
      hide_input = false;
      rounding = -1; # -1 means complete rounding (circle/oval)
      check_color = "rgb(9ccfd8)";
      fail_color = "rgb(eb6f92)"; # if authentication failed, changes outer_color and fail message color
      fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>"; # can be set to empty
      fail_transition = 300; # transition time in ms between normal outer_color and fail_color
      capslock_color = -1;
      numlock_color = -1;
      bothlock_color = -1; # when both locks are active. -1 means don't change outer color (same for above)
      invert_numlock = false; # change color if numlock is off
      swap_font_color = false; # see below
      position = "0, -20";
      halign = "center";
      valign = "center";
    };
     shape = {
       monitor = "";
       size = "360, 60";
       color = "rgba(25, 23, 36, 0.8)";
       rounding = -1;
       border_size = 4;
       border_color = "rgba(49, 116, 143, 0.8)";
       rotate = 0;
       xray = false; # if true, make a "hole" in the background (rectangle of specified size, no rotation)
       position = "0, 80";
       halign = "center";
       valign = "center";
     };
    label = [
      {
        monitor = "";
        text = "cmd[update:1000] echo $TIME";
        text_align = "center"; # center/right or any value for default left. multi-line text alignment inside label container
        color = "rgba(196, 167, 231, 1.0)";
        font_size = 100;
        font_family = "Iosevka";
        rotate = 0; # degrees, counter-clockwise
        position = "0, -40";
        halign = "center";
        valign = "top";
      }
        #{
        #  monitor = "";
        #  text = "cmd[update:300000] curl -s 'https://wttr.in/-37.99116,145.17385?format=1'";
        #  text_align = "center"; # center/right or any value for default left. multi-line text alignment inside label container
        #  color = "rgba(196, 167, 231, 1.0)";
        #  font_size = 18;
        #  font_family = "Iosevka";
        #  rotate = 0; # degrees, counter-clockwise
        #  position = "0, -200";
        #  halign = "center";
        #  valign = "top";
        #}
    ];
  };
  services.hyprpaper = {
    enable = true;
    package = inputs.hyprpaper.packages.${pkgs.hostPlatform.system}.hyprpaper;
    settings = {
      #lib.mkIf (osConfig.networking.hostName == "nano")
      preload = [ "~/pictures/wallpapers/tarantula_nebula_nano.png" ];
      wallpaper = [
        ",~/pictures/wallpapers/tarantula_nebula_nano.png"
        "eDP-1,~/pictures/wallpapers/tarantula_nebula_nano.png"
      ];
      ipc = "off";
    };
  };
  #xdg.configFile."hypr/hyprpaper.conf".text = ''
  #  preload = ~/pictures/wallpapers/tarantula_nebula_nano.png
  #  preload = ~/pictures/wallpapers/nebula1_r.png
  #  preload = ~/pictures/wallpapers/nebula2_dark.png
  #  wallpaper = ,~/pictures/wallpapers/tarantula_nebula_nano.png
  #  wallpaper = eDP-1,~/pictures/wallpapers/tarantula_nebula_nano.png
  #  wallpaper = DP-2,~/pictures/wallpapers/nebula1_r.png
  #  wallpaper = DP-3,~/pictures/wallpapers/nebula2_dark.png
  #  ipc = off
  #'';
  wayland.windowManager.hyprland = lib.mkMerge [
      (lib.mkIf (osConfig.networking.hostName == "surface") {
        settings.monitor = [
          "eDP-1,preferred,auto,2"
          "eDP-1,addreserved,0,0,0,0"
        ];
        plugins = [
          #inputs.hyprgrass.packages.${pkgs.hostPlatform.system}.default
        ];
      })
      (lib.mkIf (osConfig.networking.hostName == "nano") {
        settings.monitor = [
          "eDP-1,preferred,auto,1"
          "desc:Dell Inc. AW3423DWF 2ZVC2S3,3440x1440@165,auto,1"
        ];
      })
      (lib.mkIf (osConfig.networking.hostName == "web") {
        settings = {
          monitor = [
            #"DP-3,3440x1440@144,0x0,1" # 0x110
            "desc:Dell Inc. AW3423DWF 2ZVC2S3,3440x1440@165,0x1000,1"
            "desc:XMI Mi Monitor,3440x1440@144,3440x0,1,transform,3" # 0x110
            #"desc:ViewSonic Corporation XG2703-GS,2560x1440@120.0,3440x0,1,transform,3"
            #"DP-1,2560x1440@120.0,3440x0,1,transform,3"
            "sunshine,1920x1080,auto,1"
            "Unknown-1,disable"
          ];
          env = [
            "GDK_BACKEND,wayland"
            "QT_QPA_PLATFORM,wayland"
            "SDL_VIDEODRIVER,wayland"
            "CLUTTER_BACKEND,wayland"
            "HYPRCURSOR_THEME,rose-pine-hyprcursor"
            "HYPRCURSOR_SIZE,24"
          ];
        };
      })
    {
    package = inputs.hyprland.packages.x86_64-linux.default;
    xwayland.enable = true;
    systemd.enable = true;
    plugins = [
        #inputs.hycov.packages.${pkgs.system}.hycov
        pkgs.hyprlandPlugins.hyprfocus
        pkgs.hyprlandPlugins.hyprexpo
        pkgs.hyprlandPlugins.hyprspace
    ];
    settings = {
      exec-once = [
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "${pkgs.hyprlock}/bin/hyprlock --immediate --immediate-render"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "${pkgs.polychromatic}/bin/polychromatic-cli -o none"
        "${pkgs.wayvnc}/bin/wayvnc"
      ];
      #monitor = [",preferred,auto,1"];
      xwayland.force_zero_scaling = true;
      general = {
        gaps_in = 4;
        gaps_out = 6;
        border_size = 2;
        "col.active_border" = lib.mkForce "rgba(9ccfd899)";
        "col.inactive_border" = lib.mkForce "rgba(31748f99)";
        layout = "dwindle";
        no_focus_fallback = true;
        resize_on_border = true;
      };
      binds = {
        movefocus_cycles_fullscreen = false;
        workspace_center_on = 1;
        scroll_event_delay = 100;
      };
      decoration = {
        rounding = 20;
        blur = {
          enabled = true;
          size = 5;
          passes = 3;
          new_optimizations = true;
          ignore_opacity = true;
        };
        drop_shadow = false;
        dim_special = 0.5;
      };
      animations = {
       enabled = true;
       bezier = "overshot,0.05,0.9,0.1,1.1";
       animation = [
          "windowsIn, 1, 6, overshot, slide"
          "windowsOut, 1, 6, overshot, slide"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
          "specialWorkspace, 1, 6, overshot"
        ];
      };
      dwindle = {
        pseudotile = true;
        force_split = 2;
        #smart_split = true;
        #smart_resizing = true;
        preserve_split = true;
        split_width_multiplier = 1.6;
          #special_scale_factor = 0.90;
        no_gaps_when_only = 0;
        use_active_for_splits = true;
        default_split_ratio = 1.2;
      };
      misc = {
        disable_hyprland_logo = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        focus_on_activate = true;
        layers_hog_keyboard_focus = true;
        mouse_move_enables_dpms = false;
        key_press_enables_dpms = true;
        enable_swallow = false;
        swallow_regex = "^(kitty)$";
        swallow_exception_regex = "^(cava|wev)$";
        vfr = true;
        vrr = true;
        new_window_takes_over_fullscreen = 2;
      };
      group = {
        insert_after_current = true;
        "col.border_active" = lib.mkForce "rgba(9ccfd899)";
        "col.border_inactive" = lib.mkForce "rgba(31748f99)";
        groupbar = {
          enabled = true;
          height = 6;
          render_titles = false;
          gradients = false;
          "col.active" = lib.mkForce "rgba(9ccfd899)";
          "col.inactive" = lib.mkForce "rgba(31748f99)";
        };
      };
      cursor = {
        enable_hyprcursor = true;
        sync_gsettings_theme = true;
          #no_hardware_cursors = true;
        persistent_warps = true;
        warp_on_change_workspace = true;
        allow_dumb_copy = true;
      };
      input = {
        kb_layout = "us";
        repeat_rate = 60;
        repeat_delay = 250;
        follow_mouse = 1;
        mouse_refocus = true;
        float_switch_override_focus = 0;
        touchpad = {
          disable_while_typing = true;
          scroll_factor = 0.5;
          drag_lock = true;
          tap-and-drag = true;
          natural_scroll = true;
        };
        sensitivity = 0;
      };
      device = {
        name = "tpps/2-elan-trackpoint";
        sensitivity = -0.25;
        natural_scroll = false;
      };
      #  "elan0670:00-04f3:3150-touchpad" = {
      #    sensitivity = 0.1;
      #    natural_scroll = true;
      #  };
      #};
      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 4;
        workspace_swipe_distance = 200;
        workspace_swipe_min_speed_to_force = 3;
        workspace_swipe_cancel_ratio = 0.2;
        workspace_swipe_forever = true;
      };
      plugin = {
        touch_gestures = {
          sensitivity = 4.0;
          workspace_swipe_fingers = 4;
        };
        hyprfocus = {
          enabled = "yes";
          keyboard_focus_animation = "flash";
          mouse_focus_animation = "flash";
          bezier = [
            "bezIn, 0.5,0.0,1.0,0.5"
            "bezOut, 0.0,0.5,0.5,1.0"
          ];
          flash = {
            flash_opacity = 0.7;
            in_bezier = "bezIn";
            in_speed = 0.5;
            out_bezier = "bezOut";
            out_speed = 3;
          };
        };
        hycov = {
          overview_gappo = 60; # gas width from screem
          overview_gappi = 24; # gas width from clients
          hotarea_size = 10; # hotarea size in bottom left,10x10
          enable_hotarea = 1; # enable mouse cursor hotarea
          swipe_fingers = 3; # finger number of gesture,move any directory
          move_focus_distance = 100; # distance for movefocus,only can use 3 finger to move
          enable_gesture = 0; # enable gesture
          disable_workspace_change = 0; # disable workspace change when in overview mode
          disable_spawn = 0; # disable bind exec when in overview mode
          auto_exit = 1; # enable auto exit when no client in overview
        };
        hy3 = {
          no_gaps_when_only = false;
          node_collapse_policy = 2;
          autotile = {
            enable = false;
            ephemeral_groups = true;
            trigger_width = 800;
            trigger_height = 200;
            workspaces = "all";
          };
          tab_first_window = false;
          tabs = {
            height = 6;
            padding = 4;
            from_top = true;
            rounding = 6;
            render_text = false;
            "col.active" = "0xccc4a7e7";
            "col.urgent" = "0xccff4f4f";
            "col.inactive" = "0xcc31748f";
          };
        };
        hyprexpo = {
          columns = 3;
          gap_size = 5;
          bg_col = "rgb(111111)";
          workspace_method = "center current"; # [center/first] [workspace] e.g. first 1 or center m+1
          enable_gesture = true; # laptop touchpad
          gesture_fingers = 3;  # 3 or 4
          gesture_distance = 300; # how far is the "max"
          gesture_positive = true; # positive = swipe down. Negative = swipe up.
        };
        # TODO: https://github.com/KZDKM/Hyprspace
          #overview = {
          #  panelColor = "0xHEXCOLOR"; # Set color for the panel
          #  panelBorderColor = "0xHEXCOLOR"; # Set border color for the panel
          #  workspaceActiveBackground = "0xHEXCOLOR"; # Active workspace background color
          #  workspaceInactiveBackground = "0xHEXCOLOR"; # Inactive workspace background color
          #  workspaceActiveBorder = "0xHEXCOLOR"; # Border color for active workspace
          #  workspaceInactiveBorder = "0xHEXCOLOR"; # Border color for inactive workspace
          #  dragAlpha = 0.7; # Set alpha value for window when dragged in overview (0-1)

          #  # Layout
          #  panelHeight = 30; # Height of the panel in pixels
          #  panelBorderWidth = 2; # Border width of the panel in pixels
          #  onBottom = true; # Set to true if the panel should be at the bottom
          #  workspaceMargin = 10; # Margin between workspaces and the panel edges
          #  reservedArea = 20; # Padding for camera notch (Macbook)
          #  workspaceBorderSize = 2; # Border size for workspaces
          #  centerAligned = true; # True for center alignment, false for left alignment
          #  hideBackgroundLayers = false; # Hide background layers
          #  hideTopLayers = false; # Hide top layers
          #  hideOverlayLayers = false; # Hide overlay layers
          #  hideRealLayers = false; # Hide layers in actual workspace
          #  drawActiveWorkspace = true; # Draw active workspace as-is in overview
          #  overrideGaps = true; # Override layout gaps in overview
          #  gapsIn = 5; # Gaps inside the workspace
          #  gapsOut = 10; # Gaps outside the workspace
          #  affectStrut = true; # Push window aside, disabling also disables overrideGaps

          #  # Animation
          #  overrideAnimSpeed = 1.0; # Speed of slide-in animation

          #  # Behaviors
          #  autoDrag = true; # Always drag window when overview is open
          #  autoScroll = true; # Scroll on active workspace area switches workspace
          #  exitOnClick = true; # Exits overview on click without dragging
          #  switchOnDrop = true; # Switch workspace when window is dropped into it
          #  exitOnSwitch = true; # Exit overview on switch
          #  showNewWorkspace = true; # Add new empty workspace at the end
          #  showEmptyWorkspace = true; # Show empty workspaces between non-empty ones
          #  showSpecialWorkspace = false; # Show special workspace if any
          #  disableGestures = false; # Disable gestures
          #  reverseSwipe = false; # Reverse swipe gesture direction (for macOS style)

          #  # Touchpad gesture settings
          #  gestures.workspace_swipe_fingers = 4; # Number of fingers for swipe
          #  gestures.workspace_swipe_cancel_ratio = 0.5; # Ratio to cancel swipe
          #  gestures.workspace_swipe_min_speed_to_force = 1000; # Min speed to force switch
          #};
      };
    };
  }];
}
